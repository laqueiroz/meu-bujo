package com.meubujo.meu_bujo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import java.io.File

/**
 * UC25: widget do Meu Bujo. Os dados vêm do app (lib/dados/widget_casa.dart).
 * RN32: no widget só dá pra somar água; tocar nas tarefas (ou no resto) abre o app.
 */
abstract class BujoWidget(private val layout: Int, private val maxTarefas: Int, private val cabecalho: Boolean) :
    HomeWidgetProvider() {

  private val linhas = intArrayOf(R.id.t0, R.id.t1, R.id.t2, R.id.t3, R.id.t4, R.id.t5)

  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, layout)
      v.setOnClickPendingIntent(R.id.raiz, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))

      // copo d'água
      val temAgua = widgetData.getBoolean("agua_ok", false)
      v.setViewVisibility(R.id.agua, if (temAgua) View.VISIBLE else View.GONE)
      if (temAgua) {
        v.setTextViewText(R.id.agua_nome, widgetData.getString("agua_nome", ""))
        v.setTextViewText(R.id.agua_texto, widgetData.getString("agua_texto", ""))
        v.setProgressBar(R.id.agua_barra, 100, widgetData.getInt("agua_pct", 0), false)
        v.setTextViewText(R.id.agua_mais, widgetData.getString("agua_passo", "+"))
        v.setOnClickPendingIntent(R.id.agua_mais, HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("meubujo://agua")))
      }

      // tarefas de hoje
      if (maxTarefas > 0) {
        val n = minOf(widgetData.getInt("n_tarefas", 0), maxTarefas)
        for (i in 0 until maxTarefas) {
          val linha = linhas[i]
          if (i < n) {
            val feita = widgetData.getBoolean("t${i}_feita", false)
            val texto = widgetData.getString("t${i}_texto", "") ?: ""
            v.setViewVisibility(linha, View.VISIBLE)
            v.setTextViewText(linha, (if (feita) "✓   " else "•   ") + texto)
            v.setTextColor(linha, context.getColor(if (feita) R.color.widget_suave else R.color.widget_texto))
            // tarefa no widget é só pra ver: marcar como feita é dentro do app
            v.setOnClickPendingIntent(linha, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
          } else {
            v.setViewVisibility(linha, View.GONE)
          }
        }
        v.setViewVisibility(R.id.vazio, if (n == 0) View.VISIBLE else View.GONE)
        // o que não coube (sempre feitas ou as abertas menos recentes) vira só um "+N"
        val fora = widgetData.getInt("n_total", n) - n
        v.setViewVisibility(R.id.mais, if (fora > 0) View.VISIBLE else View.GONE)
        if (fora > 0) v.setTextViewText(R.id.mais, "+ $fora no app")
      }

      if (cabecalho) {
        v.setTextViewText(R.id.data, widgetData.getString("data", ""))
        v.setTextViewText(R.id.fala, widgetData.getString("fala", ""))
        val gata = widgetData.getString("gata", null)
        if (gata != null && File(gata).exists()) v.setImageViewBitmap(R.id.gata, BitmapFactory.decodeFile(gata))
      }

      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

/** Faixa (tela de bloqueio): próxima tarefa que falta, quantas faltam e a água com +250 ml. */
class WidgetFaixa : HomeWidgetProvider() {
  override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
    for (id in appWidgetIds) {
      val v = RemoteViews(context.packageName, R.layout.widget_faixa)
      v.setOnClickPendingIntent(R.id.raiz, HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java))
      v.setTextViewText(R.id.proxima, widgetData.getString("proxima", "Meu Bujo"))
      val abertas = widgetData.getInt("abertas", 0)
      v.setViewVisibility(R.id.resto, if (abertas > 1) View.VISIBLE else View.GONE)
      v.setTextViewText(R.id.resto, "e mais ${abertas - 1} pra hoje")
      val temAgua = widgetData.getBoolean("agua_ok", false)
      v.setViewVisibility(R.id.agua, if (temAgua) View.VISIBLE else View.GONE)
      v.setViewVisibility(R.id.agua_mais, if (temAgua) View.VISIBLE else View.GONE)
      if (temAgua) {
        v.setProgressBar(R.id.agua_barra, 100, widgetData.getInt("agua_pct", 0), false)
        v.setTextViewText(R.id.agua_texto, widgetData.getString("agua_texto", ""))
        v.setTextViewText(R.id.agua_mais, widgetData.getString("agua_passo", "+"))
        v.setOnClickPendingIntent(R.id.agua_mais, HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("meubujo://agua")))
      }
      appWidgetManager.updateAppWidget(id, v)
    }
  }
}

/** Pequeno: copo d'água com +250 ml. */
class WidgetPequeno : BujoWidget(R.layout.widget_pequeno, 0, false)

/** Médio: copo e até 3 tarefas abertas de hoje. */
class WidgetMedio : BujoWidget(R.layout.widget_medio, 3, false)

/** Grande: data, gatinha, até 6 tarefas (prioritárias primeiro) e barra de água. */
class WidgetGrande : BujoWidget(R.layout.widget_grande, 6, true)
