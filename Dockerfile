FROM ruby:2.2.3

ADD ./ /src
WORKDIR /src
ENTRYPOINT ["/src/sinknode.rb"]
