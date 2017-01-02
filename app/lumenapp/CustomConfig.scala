package lumenapp

import lumen.{DefaultConfig, ShowDocumentPresenter, ViewConfig}

/**
  * Custom Configuration illustrating how to override options from DefaultConfig.
  */
class CustomConfig extends DefaultConfig {

  override val defaultPerPage = 25

  override def viewConfigs = {
    val old = super.viewConfigs
    old ++ Map(
      "show" -> old("show").copy(titleField = "title_display")
    )
  }

}
