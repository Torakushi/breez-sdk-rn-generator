{%- let e = ci.get_enum_definition(name).unwrap() %}
{%- if e.is_flat() %}

static func  as{{ type_name }}(type: String) throws -> {{ type_name }} {
    switch(type) {
    {%- for variant in e.variants() %}

    case "{{variant.name()|var_name|unquote}}":         
        return {{ type_name }}.{{variant.name()|var_name|unquote}}

    {%- endfor %}
    
    default: throw SdkError.Generic(message: "Invalid variant \(type) for enum {{ type_name }}")
    }
}

static func valueOf({{ type_name|var_name|unquote }}: {{ type_name }}) -> String {
        switch({{ type_name|var_name|unquote }}) {
        {%- for variant in e.variants() %}

        case .{{variant.name()|var_name|unquote}}:         
            return "{{variant.name()|var_name|unquote}}"

        {%- endfor %}
            
        }
    }

{%- else %}

static func as{{ type_name }}(data: [String: Any?]) throws -> {{ type_name }} {
    let type = data["type"] as! String

    {%- for variant in e.variants() %}
        if (type == "{{ variant.name()|var_name|unquote }}") {
            {%- if variant.has_fields() %}
            {% let field = variant.fields()[0] %}
            {%- match field.type_() %}         
            {%- when Type::Optional(_) %}
                {% if field.type_()|inline_optional_field(ci) -%}
                let _{{field.name()|var_name|unquote}} = data["{{field.name()|var_name|unquote}}"] as? {{field.type_()|rn_type_name(ci, true)}}
                {% else -%}
                var _{{field.name()|var_name|unquote}}: {{field.type_()|type_name}}
                if let {{field.name()|var_name|unquote|temporary}} = data["{{field.name()|var_name|unquote}}"] as? {{field.type_()|rn_type_name(ci, true)}} {
                    _{{field.name()|var_name|unquote}} = {{field.type_()|render_from_map(ci, field.name()|var_name|unquote|temporary)}}
                }
                {% endif -%}
            {%- else %}
            {% if field.type_()|inline_optional_field(ci) -%}
            guard let _{{field.name()|var_name|unquote}} = data["{{field.name()|var_name|unquote}}"] as? {{field.type_()|rn_type_name(ci, true)}} else { throw SdkError.Generic(message: "Missing mandatory field {{field.name()|var_name|unquote}} for type {{ type_name }}") }
            {%- else -%}
            guard let {{field.name()|var_name|unquote|temporary}} = data["{{field.name()|var_name|unquote}}"] as? {{field.type_()|rn_type_name(ci, true)}} else { throw SdkError.Generic(message: "Missing mandatory field {{field.name()|var_name|unquote}} for type {{ type_name }}") }
            let _{{field.name()|var_name|unquote}} = {{field.type_()|render_from_map(ci, field.name()|var_name|unquote|temporary)}}
            {% endif -%}        
            {% endmatch %}            
            return {{ type_name }}.{{ variant.name()|var_name|unquote }}({{ variant.fields()[0].name()|var_name|unquote }}: _{{field.name()|var_name|unquote}})                         
            {%- else %}
            return {{ type_name }}.{{ variant.name()|var_name|unquote }}          
            {%- endif %}       
        }        
    {%- endfor %}    

    throw SdkError.Generic(message: "Invalid enum variant \(type) for enum {{ type_name }}")
}

static func dictionaryOf({{ type_name|var_name|unquote }}: {{ type_name }}) -> [String: Any?] {    
    switch ({{ type_name|var_name|unquote }}) {
    {%- for variant in e.variants() %}
    {% if variant.has_fields() %}
    case let .{{ variant.name()|var_name|unquote }}(
        {% for f in variant.fields() %}{{f.name()|var_name|unquote}}{%- endfor %}
    ):
    {% else %}
    case .{{ variant.name()|var_name|unquote }}:  
    {% endif -%}
        return [
            "type": "{{ variant.name()|var_name|unquote }}",
            {%- for f in variant.fields() %}
            "{{ f.name()|var_name|unquote }}": {{ f.type_()|render_to_map(ci,"",f.name()|var_name|unquote, false) }},             
            {%- endfor %}
        ] 
    {%- endfor %}   
    }    
}

{%- endif %}