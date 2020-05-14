FROM kbase/sdkbase2:latest
MAINTAINER KBase Developer
# update kb-sdk
RUN cd /root/src/kb_sdk \
    && git remote add iaa https://github.com/ialarmedalien/kb_sdk.git \
    && git pull iaa better_perl_and_tests \
    && git checkout better_perl_and_tests \
    && make \
    && cp bin/kb-sdk /usr/local/bin

# -----------------------------------------
# In this section, you can install any system dependencies required
# to run your App.  For instance, you could place an apt-get update or
# install line here, a git checkout to download code, or run any other
# installation scripts.

WORKDIR /kb/module
COPY ./cpanfile /kb/module/cpanfile
# install cpan dependencies
RUN cpanm --installdeps .
# remove installation leftovers
RUN cd ~ && rm -rf .cpanm

COPY ./ /kb/module

WORKDIR /kb/module

RUN mkdir -p /kb/module/work && \
    chmod -R a+rw /kb/module && \
    make all

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
