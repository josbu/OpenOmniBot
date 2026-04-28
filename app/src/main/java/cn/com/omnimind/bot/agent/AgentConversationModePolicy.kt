package cn.com.omnimind.bot.agent

import cn.com.omnimind.baselib.i18n.PromptLocale
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive

object AgentConversationModePolicy {
    const val NORMAL_MODE = "normal"
    const val SUBAGENT_MODE = "subagent"

    private val subagentRestrictedToolNames = setOf(
        "schedule_task_create",
        "schedule_task_list",
        "schedule_task_update",
        "schedule_task_delete",
        "alarm_reminder_create",
        "alarm_reminder_list",
        "alarm_reminder_delete",
        "calendar_list",
        "calendar_event_create",
        "calendar_event_list",
        "calendar_event_update",
        "calendar_event_delete",
        "subagent_dispatch"
    )

    fun isSubagentMode(conversationMode: String?): Boolean {
        return conversationMode?.trim()?.equals(SUBAGENT_MODE, ignoreCase = true) == true
    }

    fun isToolRestrictedInConversationMode(
        toolName: String,
        conversationMode: String?
    ): Boolean {
        if (!isSubagentMode(conversationMode)) {
            return false
        }
        return subagentRestrictedToolNames.contains(toolName.trim())
    }

    fun restrictedToolNamesForConversationMode(conversationMode: String?): Set<String> {
        return if (isSubagentMode(conversationMode)) {
            subagentRestrictedToolNames
        } else {
            emptySet()
        }
    }

    fun filterToolDefinitionsForConversationMode(
        definitions: List<JsonObject>,
        conversationMode: String?
    ): List<JsonObject> {
        val restricted = restrictedToolNamesForConversationMode(conversationMode)
        if (restricted.isEmpty()) {
            return definitions
        }
        return definitions.filterNot { definition ->
            val toolName = (definition["function"] as? JsonObject)
                ?.get("name")
                ?.jsonPrimitive
                ?.contentOrNull
                ?.trim()
                .orEmpty()
            restricted.contains(toolName)
        }
    }

    fun buildScheduledSubagentExecutionMessage(
        rawUserMessage: String,
        scheduleTaskTitle: String?,
        locale: PromptLocale
    ): String {
        val normalizedMessage = rawUserMessage.trim()
        if (normalizedMessage.isEmpty()) {
            return normalizedMessage
        }
        val title = scheduleTaskTitle?.trim()?.ifEmpty { null }
        return when (locale) {
            PromptLocale.ZH_CN -> {
                val prefix = "你正在执行一个已经触发的定时子任务"
                if (normalizedMessage.startsWith(prefix)) {
                    normalizedMessage
                } else {
                    buildString {
                        appendLine(
                            title?.let { "$prefix「$it」。" } ?: "${prefix}。"
                        )
                        appendLine("上层已经完成时间安排，本轮只需要现在立刻完成实际任务，不要重新安排时间。")
                        appendLine()
                        appendLine("执行约束：")
                        appendLine("1. 不要再次创建、修改或删除定时任务、提醒闹钟或日历。")
                        appendLine("2. 不要再次调用 `subagent_dispatch` 分派新的 subagent。")
                        appendLine("3. 如果原文里出现“每天/几点/定时/提醒”等时间描述，把它们当作背景信息，不要把它们理解成新的调度请求。")
                        appendLine("4. 只保留真正需要执行的动作，直接开始完成任务。")
                        appendLine()
                        appendLine("原始任务：")
                        append(normalizedMessage)
                    }
                }
            }

            PromptLocale.EN_US -> {
                val prefix = "You are executing an already-triggered scheduled subagent task"
                if (normalizedMessage.startsWith(prefix)) {
                    normalizedMessage
                } else {
                    buildString {
                        appendLine(
                            title?.let { "$prefix \"$it\"." } ?: "$prefix."
                        )
                        appendLine("The parent layer has already handled the timing, so this turn must execute the real task right now instead of scheduling it again.")
                        appendLine()
                        appendLine("Execution rules:")
                        appendLine("1. Do not create, update, or delete scheduled tasks, reminder alarms, or calendar events again.")
                        appendLine("2. Do not call `subagent_dispatch` to spawn more subagents.")
                        appendLine("3. If the original text mentions phrases like daily, at a specific time, scheduled, or remind me, treat them as background context rather than a new scheduling request.")
                        appendLine("4. Keep only the action that needs to be executed now, and start doing it directly.")
                        appendLine()
                        appendLine("Original task:")
                        append(normalizedMessage)
                    }
                }
            }
        }
    }
}
