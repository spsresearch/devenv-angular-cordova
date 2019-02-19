FROM node:8.11
ENV TZ=Europe/Oslo
ENV LANG C.UTF-8
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
# TODO There is actually a apt-get package "android-sdk" that install all the things we need, Java, Gradle, and Android SDK, for future iterations we could look into using that instead, however it has 2 issues at the time of writing
# 1. Not available on the docker image, can add source as workaround
# 2. Failed to build because of missing accepted licenses, according to documentation you're supposed to use sdkmanager but it's missing from the package
# Install Java
ENV JAVA_HOME /usr/lib/jvm/java-8-oracle
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list \
  && echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list \
  && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 \
  && echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections \
  && apt-get update && apt-get install -y oracle-java8-installer
# Install Gradle
ENV GRADLE_HOME="/home/node/.local/gradle-4.8.1"
ENV PATH="${GRADLE_HOME}/bin:${PATH}"
RUN mkdir -p /home/node/.local/ \
  && wget -q -O gradle-4.8.1-bin.zip https://services.gradle.org/distributions/gradle-4.8.1-bin.zip?_ga=2.124233551.434846438.1530268329-532553301.1530268329 \
  && apt-get update && apt-get -y install unzip \
  && unzip -qq -d /home/node/.local gradle-4.8.1-bin.zip
# Install Android SDK
ENV ANDROID_SDK_ROOT="/home/node/.local/android-sdk-linux/"
RUN mkdir -p /home/node/.local/ \
  && apt-get update && apt-get -y install unzip \
  && wget -q https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip \
  && unzip -qq -d $ANDROID_SDK_ROOT sdk-tools-linux-4333796.zip \
  && yes | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager --licenses \
  && yes | ${ANDROID_SDK_ROOT}/tools/bin/sdkmanager "platform-tools" "platforms;android-28" "build-tools;28.0.3"
# Install dumb-init (Very handy for easier signal handling of SIGINT/SIGTERM/SIGKILL etc.)
RUN wget https://github.com/Yelp/dumb-init/releases/download/v1.2.0/dumb-init_1.2.0_amd64.deb \
 && dpkg -i dumb-init_*.deb
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
# Install Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update && apt-get install -y google-chrome-stable
RUN chown -R node:node /home/node
USER node
WORKDIR /home/node
COPY . /home/node
# Install CLIs and required utilities
RUN git clone --depth=1 https://github.com/magicmonty/bash-git-prompt.git ~/.local/bash-git-prompt
RUN npm install -g npm@6.1 @angular/cli@6.0 cordova@8.0 smartcrop-cli@2.0 node-opencv firebase-tools heroku cloc@latest \
 && mkdir -p /home/node/.local
ENV PATH="/home/node/.npm-packages/bin:${PATH}"
EXPOSE 4200 9876 9222 8888 9005
CMD [ "npm", "run" ]
