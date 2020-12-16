FROM ialarmedalien/sdkbase2_perl

ENV APP_DIR /kb/module
ENV KB_DEPLOYMENT_CONFIG /kb/module/deploy.cfg
ENV PERL5LIB="/kb/module/lib:${PERL5LIB}"

WORKDIR /kb/module

COPY ./ /kb/module

# update kb-sdk
WORKDIR /root/src/kb_sdk
RUN git checkout develop \
    && make \
    && cp bin/kb-sdk /usr/local/bin \
    && cd /kb/module \
    # check out the relation_engine repo (if required)
    && if [ -d relation_engine ]; then \
        echo "relation engine repo ready to go"; \
    else \
        git clone https://github.com/kbase/relation_engine.git; \
    fi \
    && mkdir -p /kb/module/work \
    && chmod -R a+rw /kb/module \
    && chmod +x /kb/module/scripts/*.sh \
    && make all

WORKDIR /kb/module

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
