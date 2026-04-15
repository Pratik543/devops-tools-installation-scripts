# Integrating with Jenkins

## Install plugins in Jenkins

To integrate OWASP Dependency-Check Tool with Jenkins, you have to install a plugin called `OWASP Dependency-Check Plugin`

Plugin Name: `OWASP Dependency-Check Plugin`

This plug-in can independently execute a Dependency-Check analysis and visualize results.

Dependency-Check is a utility that identifies project dependencies and checks if there are any known, publicly disclosed, vulnerabilities.

To install this plugin go to:

> Manage Jenkins > Manage Plugins > Available

Under available search for the `OWASP Dependency-Check Plugin` and install it.

Even though restart is not mandatory , it is recommended to restart. Once download is done, check on restart jenkins.

If restart doesn’t start properly, then navigate to <http://localhost:8080/restart> to restart jenkins manually.

## Add Dependency-Check installation to Jenkins

* To work with the installed plugin you have to add Dependency-Check installation in Global Tool configuration which will be installed by Jenkins automatically
* Navigate to the Global tools configuration (Manage Jenkins -> Global Tools Configuration) to configure dependency check.
  > Manage Jenkins > Global Tool Configuration > Dependency-Check
* Click on `Add Dependency-Check` and provide any ***unique name*** that you are going to use later in your job configuration or pipeline script.
* Check `Install automatically` and select the version you want to use, latest version is recommended.
* Apply and save the configuration.
* From here, the dependency check can be directly invoked in a project, or a pipeline script can be used to invoke it.

## Using Dependency-Check in Free Style Project

### Invoke Dependency-Check

* To use Dependency-Check for a `Free Style Project` Job go to `Build Environment` section.
* In Build Environment section click on `Add build step` and select `Invoke Dependency-Check`.
* Under Dependency-Check installation add the ***unique name*** that was mentioned in Global Tool Configuration.
* Leave the remaining fields empty to use default arguments.
* Apply and save the configuration.

### Publish Dependency-Check results

* The xml report generated in previous build step `Invoke Dependency-Check` can be used to visualize vulnerability data in a graphical format on Jenkins Job page.
* For this you have add a Post-build Actions, under `Post-build Actions` select `Publish Dependency-Check results`.
* Leave it empty to use the default values.
* Apply and save the configuration.

## Using Dependency-Check in Pipeline script

* The Dependency-Check can be invoked using a pipeline script. The pipeline script generator functionality can be accessed from the URL : <http://localhost:8080/pipeline-syntax/>
* To use this plugin modify and add below code to your pipeline script.

```sh
pipeline {
    agent any
    stages {
        stage('Checking for Vulnerabilities') {
            steps {
                dependencycheck additionalArguments: '--scan ./ --out dependency-check-report.xml --format XML', odcInstallation: 'Dependency Checker' # Replace `Dependency Checker` with the installation name you have saved.
            }
        }
    }
    post {
        always {
            dependencyCheckPublisher pattern: 'dependency-check-report.xml'
        }
    }
}
```

or you can also use above code as

```sh
pipeline {
    agent any
    stages {
        stage('Checking for Vulnerabilities') {
            steps {
                dependencycheck additionalArguments: '--scan ./', odcInstallation: 'Dependency Checker' # Replace `Dependency Checker` with the installation name you have saved.
            }
        }
    }
    post {
        always {
            dependencyCheckPublisher()
        }
    }
}
```

or you can also remove Post Build and add it in stage

```sh
pipeline {
    agent any
    stages {
        stage('Checking for Vulnerabilities') {
            steps {
                dependencycheck additionalArguments: '--scan ./', odcInstallation: 'Dependency Checker' # Replace `Dependency Checker` with the installation name you have saved.
                dependencyCheckPublisher()
            }
        }
    }
}
```

To know more on how to use `dependencyCheck` and `dependencyCheckPublisher` in the pipeline steps visit official site [OWASP Dependency-Check Plugin](https://www.jenkins.io/doc/pipeline/steps/dependency-check-jenkins-plugin/) for reference.