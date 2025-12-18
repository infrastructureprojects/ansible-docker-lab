def pretty_env(value: str) -> str:
    return str(value).strip().upper()

class FilterModule(object):
    def filters(self):
        return {"pretty_env": pretty_env}
