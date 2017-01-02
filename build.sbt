import com.typesafe.sbt.packager.MappingsHelper._

name := """lumen-sample-app"""

version := "1.0-SNAPSHOT"

lazy val root = (project in file("."))
.dependsOn(RootProject(file("../lumen")))
.enablePlugins(PlayScala)

scalaVersion := "2.11.8"

libraryDependencies ++= Seq(
  jdbc,
  cache,
  ws,
  "org.scalatestplus.play" %% "scalatestplus-play" % "1.5.1" % Test
// in real setup, use this line and remove dependsOn above
//  "com.codefork" % "lumen_2.11" % "1.0-SNAPSHOT"
)

// this adds app/views dir to scalate path
unmanagedResourceDirectories in Compile += baseDirectory.value / "app" / "views"

mappings in Universal ++= directory("solr")
mappings in Universal ++= directory("indexing")
