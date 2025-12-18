from __future__ import annotations
from ansible.plugins.callback import CallbackBase

class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = "stdout"
    CALLBACK_NAME = "pretty_log"

    def v2_runner_on_ok(self, result):
        host = result._host.get_name()
        task = result.task_name or "task"
        self._display.display(f"✅ [{host}] {task}")

    def v2_runner_on_failed(self, result, ignore_errors=False):
        host = result._host.get_name()
        task = result.task_name or "task"
        self._display.display(f"❌ [{host}] {task} -> FAILED", color="red")
