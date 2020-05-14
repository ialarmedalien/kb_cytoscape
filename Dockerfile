FROM ialarmedalien/modernperl_base:latest

COPY ./ /kb/module

WORKDIR /kb/module

RUN mkdir -p /kb/module/work && \
    chmod -R a+rw /kb/module && \
    make all

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]
