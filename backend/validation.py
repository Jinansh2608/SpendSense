from cerberus import Validator

def validate_payload(payload, schema):
    v = Validator(schema)
    if not v.validate(payload):
        return v.errors
    return None


bulk_prediction_schema = {
    "uid": {"type": "string", "required": True},
    "messages": {
        "type": "list",
        "required": True,
        "schema": {
            "type": "dict",
            "schema": {
                "sms": {"type": "string", "required": True},
                "sender": {"type": "string", "required": True},
            },
        },
    },
}

bill_parse_schema = {
    "uid": {"type": "string", "required": True},
    "messages": {
        "type": "list",
        "required": True,
        "schema": {
            "type": "dict",
            "schema": {
                "body": {"type": "string", "required": True},
                "sender": {"type": "string", "required": True},
            },
        },
    },
}

budget_schema = {
    "uid": {"type": "string", "required": True},
    "name": {"type": "string", "required": True},
    "cap": {"type": "float", "required": True},
    "currency": {"type": "string", "required": True},
    "period": {"type": "string", "required": True},
}

update_budget_schema = {
    "name": {"type": "string", "required": False},
    "cap": {"type": "float", "required": False},
    "currency": {"type": "string", "required": False},
    "period": {"type": "string", "required": False},
}
