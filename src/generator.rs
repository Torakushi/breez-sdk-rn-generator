use anyhow::Result;
use askama::Template;
use camino::Utf8Path;
use serde::*;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::process::Command;
use uniffi_bindgen::{BindingGenerator, BindingGeneratorConfig, ComponentInterface};

use crate::{gen_kotlin, gen_typescript};

pub struct RNBindingGenerator {}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct RNConfig {
    package_name: Option<String>,
}

impl RNConfig {}

impl BindingGeneratorConfig for RNConfig {
    fn get_entry_from_bindings_table(_bindings: &toml::value::Value) -> Option<toml::value::Value> {
        if let Some(table) = _bindings.as_table() {
            table.get("rn").map(|v| v.clone())
        } else {
            None
        }
    }

    fn get_config_defaults(ci: &ComponentInterface) -> Vec<(String, toml::value::Value)> {
        vec![
            (
                "package_name".to_string(),
                toml::value::Value::String(ci.namespace().to_string()),
            ),
            (
                "cdylib_name".to_string(),
                toml::value::Value::String(ci.namespace().to_string()),
            ),
        ]
    }
}

impl RNBindingGenerator {
    fn write_kotlin_bindings(
        &self,
        ci: &ComponentInterface,
        config: &RNConfig,
        out_dir: &Utf8Path,
    ) -> Result<()> {
        let res = self::gen_kotlin::Generator::new(config.clone(), &ci)
            .render()
            .map_err(anyhow::Error::new)?;
        print!("{}", res);
        let mut out_file = out_dir.join(Utf8Path::new("android/src/main/java/com/breezsdk"));
        fs::create_dir_all(out_file.clone())?;
        out_file.push(Utf8Path::new("BreezSDKMapper.kt"));
        let mut f = File::create(&out_file)?;
        write!(f, "{}", res)?;
        if let Err(e) = Command::new("ktlint").arg("-F").arg(&out_file).output() {
            println!(
                "Warning: Unable to auto-format {} using ktlint: {:?}",
                out_file.file_name().unwrap(),
                e
            )
        }
        print!("{out_file}");
        Ok(())
    }

    fn write_typescript_bindings(
        &self,
        ci: &ComponentInterface,
        config: &RNConfig,
        out_dir: &Utf8Path,
    ) -> Result<()> {
        let res = self::gen_typescript::Generator::new(config.clone(), &ci)
            .render()
            .map_err(anyhow::Error::new)?;
        print!("{}", res);
        let mut out_file = out_dir.join(Utf8Path::new("src"));
        fs::create_dir_all(out_file.clone())?;
        out_file.push(Utf8Path::new("index.ts"));
        let mut f = File::create(&out_file)?;
        write!(f, "{}", res)?;
        if let Err(e) = Command::new("tslint").arg("--fix").arg(&out_file).output() {
            println!(
                "Warning: Unable to auto-format {} using tslint: {:?}",
                out_file.file_name().unwrap(),
                e
            )
        }
        print!("{out_file}");
        Ok(())
    }
}

impl BindingGenerator for RNBindingGenerator {
    type Config = RNConfig;

    fn write_bindings(
        &self,
        ci: ComponentInterface,
        config: Self::Config,
        out_dir: &Utf8Path,
    ) -> Result<()> {
        self.write_kotlin_bindings(&ci, &config, out_dir)?;
        self.write_typescript_bindings(&ci, &config, out_dir)?;
        Ok(())
    }
}
