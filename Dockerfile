FROM rranshous/mosquitto

RUN apt-get update
RUN apt-get install -y ruby

ADD ./ /src
WORKDIR /src
ENTRYPOINT ["/src/sinknode.rb"]
