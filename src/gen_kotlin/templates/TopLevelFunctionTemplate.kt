    
    @ReactMethod
    fun {{ func.name()|fn_name|unquote }}({%- call kt::arg_list_decl(func) -%}promise: Promise) {
        executor.execute {
            try {
{%- for arg in func.arguments() -%}
    {%- match arg.type_() %}
    {%- when Type::Optional(_) %}
    {%- when Type::Record(_) %}
                val {{arg.type_()|type_name|var_name|unquote}} = as{{arg.type_()|type_name}}({{ arg.name()|var_name|unquote }}) ?: run { throw SdkException.Generic("Missing mandatory field {{arg.name()|var_name|unquote}} of type {{ arg.type_()|type_name }}") }
    {%- else %}
    {%- endmatch %}
{%- endfor %}
                val res = {{ obj_interface }}{{ func.name()|fn_name|unquote }}({%- call kt::arg_list(func) -%})
{%- match func.return_type() -%}
{%- when Some with (return_type) %}
    {%- match return_type %}
    {%- when Type::Optional(inner) %}
        {%- let unboxed = inner.as_ref() %}
                if (res != null) {
                    promise.resolve({% call kt::return_value(unboxed) %})
                } else {
                    promise.reject(GENERIC_CODE, "No result found")
                }
    {%- else %}
                promise.resolve({% call kt::return_value(return_type) %})
    {%- endmatch %}
{%- when None %}
                promise.resolve(readableMapOf("status" to "ok"))
{%- endmatch %}
            } catch (e: SdkException) {
                promise.reject(e.javaClass.simpleName, e.message, e)
            }
        }
    }