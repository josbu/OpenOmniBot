package cn.com.omnimind.bot.agent

import cn.com.omnimind.baselib.i18n.PromptLocale
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AgentConversationModePolicyTest {

    @Test
    fun subagentModeFiltersRecursivePlanningTools() {
        val definitions = AgentToolDefinitions.staticTools(PromptLocale.ZH_CN) +
            AgentToolDefinitions.memoryTools(PromptLocale.ZH_CN) +
            AgentToolDefinitions.subagentTools(PromptLocale.ZH_CN)

        val filtered = AgentConversationModePolicy.filterToolDefinitionsForConversationMode(
            definitions = definitions,
            conversationMode = AgentConversationModePolicy.SUBAGENT_MODE
        )
        val toolNames = filtered.mapNotNull { definition ->
            ((definition["function"] as? JsonObject)
                ?.get("name")
                ?.jsonPrimitive
                ?.contentOrNull)
        }

        assertFalse(toolNames.contains("schedule_task_create"))
        assertFalse(toolNames.contains("alarm_reminder_create"))
        assertFalse(toolNames.contains("calendar_event_create"))
        assertFalse(toolNames.contains("subagent_dispatch"))
        assertTrue(toolNames.contains("vlm_task"))
        assertTrue(toolNames.contains("memory_search"))
    }

    @Test
    fun scheduledSubagentPromptIsWrappedIntoExecutionMode() {
        val prompt = AgentConversationModePolicy.buildScheduledSubagentExecutionMessage(
            rawUserMessage = "每天 9 点去检查企业微信未读并回复重要消息",
            scheduleTaskTitle = "早间消息处理",
            locale = PromptLocale.ZH_CN
        )

        assertTrue(prompt.contains("已经触发的定时子任务"))
        assertTrue(prompt.contains("不要再次创建、修改或删除定时任务"))
        assertTrue(prompt.contains("不要再次调用 `subagent_dispatch`"))
        assertTrue(prompt.contains("每天 9 点去检查企业微信未读并回复重要消息"))
    }

    @Test
    fun scheduledSubagentPromptIsWrappedIntoExecutionModeInEnglish() {
        val prompt = AgentConversationModePolicy.buildScheduledSubagentExecutionMessage(
            rawUserMessage = "Every day at 9:00 check unread Slack messages and reply to important ones",
            scheduleTaskTitle = "Morning message triage",
            locale = PromptLocale.EN_US
        )

        assertTrue(prompt.contains("already-triggered scheduled subagent task"))
        assertTrue(prompt.contains("Do not create, update, or delete scheduled tasks"))
        assertTrue(prompt.contains("Do not call `subagent_dispatch`"))
        assertTrue(prompt.contains("Every day at 9:00 check unread Slack messages"))
    }
}
