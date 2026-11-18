allprojects {
    repositories {
        maven { url = uri("https://mirrors.cloud.tencent.com/nexus/repository/maven-public/") }
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Force plugin modules (e.g. older geocoding_android) onto compileSdk 36.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        runCatching {
            fun methodsOf(target: Any) = generateSequence(target.javaClass) { it.superclass }
                .flatMap { it.methods.asSequence() }
                .distinctBy { "${it.name}/${it.parameterCount}" }
            val sourceSets = methodsOf(androidExt)
                .firstOrNull { it.name == "getSourceSets" && it.parameterCount == 0 }
                ?.invoke(androidExt) ?: return@runCatching
            val main = methodsOf(sourceSets)
                .firstOrNull { it.name == "getByName" && it.parameterCount == 1 }
                ?.invoke(sourceSets, "main") ?: return@runCatching
            val javaSource = methodsOf(main)
                .firstOrNull { it.name == "getJava" && it.parameterCount == 0 }
                ?.invoke(main)
            if (javaSource != null) {
                val srcDirs = methodsOf(javaSource)
                    .firstOrNull { it.name == "getSrcDirs" && it.parameterCount == 0 }
                    ?.invoke(javaSource) as? Iterable<*>
                val kept = srcDirs
                    ?.mapNotNull { it?.toString() }
                    ?.filterNot { it.replace('\\', '/').endsWith("src/main/kotlin") }
                if (srcDirs != null && kept != null && kept.size != srcDirs.count()) {
                    methodsOf(javaSource)
                        .firstOrNull { it.name == "setSrcDirs" && it.parameterCount == 1 }
                        ?.invoke(javaSource, kept)
                }
            }
            val kotlinSource = methodsOf(main)
                .firstOrNull { it.name == "getKotlin" && it.parameterCount == 0 }
                ?.invoke(main)
            kotlinSource?.let { source ->
                methodsOf(source)
                    .firstOrNull { it.name == "srcDir" && it.parameterCount == 1 }
                    ?.invoke(source, "src/main/kotlin")
            }
        }.onFailure {
            if (project.name == "home_widget") {
                logger.lifecycle("home_widget source-set fix failed: ${it.message}")
            }
        }
        runCatching {
            val method =
                androidExt.javaClass.methods.firstOrNull { m ->
                    (m.name == "setCompileSdkVersion" || m.name == "setCompileSdk") &&
                        m.parameterCount == 1
                } ?: return@runCatching
            val param = method.parameterTypes[0]
            when {
                param == Int::class.javaPrimitiveType || param == Int::class.javaObjectType ->
                    method.invoke(androidExt, 36)
                param == Integer::class.java -> method.invoke(androidExt, Integer.valueOf(36))
                else -> method.invoke(androidExt, 36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
