package pipeline

# Define the target Organization ID
restricted_org := "Workshop"

deny[msg] {
    # 1. Check if the pipeline belongs to the 'Workshop' Org
    input.pipeline.orgIdentifier == restricted_org
    
    # 2. Check if the pipeline is NOT using an Account-level template
    not is_account_template(input.pipeline)
    
    msg := "Access Denied: In the 'Workshop' organization, pipelines must be created from an Account-level Template."
}

# Helper rule to verify the template reference
is_account_template(p) {
    # Ensure the template object exists and the reference starts with 'account.'
    startswith(p.template.templateRef, "account.")
}