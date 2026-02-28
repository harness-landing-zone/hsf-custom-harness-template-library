package pipeline

deny[msg] {
    # Scope check: Only apply for the workshop organization
    input.pipeline.orgIdentifier == "workshop"

    # Violation check 1: No template present
    not input.pipeline.template

    msg := "HSF WARNING: Direct YAML pipelines are detected in the Workshop Org. Best practice is to use an Account-Level Template."
}

deny[msg] {
    # Scope check: Only apply for the workshop organization
    input.pipeline.orgIdentifier == "workshop"

    # Violation check 2: Template exists but isn't the 'Gold Standard'
    input.pipeline.template
    input.pipeline.template.identifier != "hsf_standard_web_service"

    msg := "HSF WARNING: Using template '" + input.pipeline.template.identifier + "'. Note: 'hsf_standard_web_service' is the recommended standard for this Workshop."
}
