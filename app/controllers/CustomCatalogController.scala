package controllers

import com.github.tototoshi.play2.scalate.Scalate
import com.google.inject.Inject
import lumen.controllers.CatalogController
import lumen.{Config, LumenApp, ShowDocumentPresenter, ViewConfig}
import play.api.i18n.MessagesApi

class CustomCatalogController @Inject() (override val messagesApi: MessagesApi, scalate: Scalate, config: Config, app: LumenApp)
  extends CatalogController(messagesApi, scalate, config, app) {

}
