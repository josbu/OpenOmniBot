package cn.com.omnimind.bot.share

import android.content.Context

object SharedOpenPreferenceStore {
    const val MODE_DEFAULT = "default"
    const val MODE_WORKSPACE = "workspace"

    private const val PREFS_NAME = "shared_open_preferences"
    private const val KEY_OPEN_MODE = "open_mode"

    fun getOpenMode(context: Context): String {
        val saved = prefs(context).getString(KEY_OPEN_MODE, MODE_DEFAULT)
        return normalizeOpenMode(saved)
    }

    fun setOpenMode(context: Context, mode: String): String {
        val normalized = normalizeOpenMode(mode)
        prefs(context).edit().putString(KEY_OPEN_MODE, normalized).apply()
        return normalized
    }

    fun normalizeOpenMode(mode: String?): String {
        return when (mode?.trim()?.lowercase()) {
            MODE_WORKSPACE -> MODE_WORKSPACE
            else -> MODE_DEFAULT
        }
    }

    private fun prefs(context: Context) =
        context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
}
