FROM postgres:16

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    postgresql-server-dev-16 \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/pgbigm/pg_bigm.git \
    && cd pg_bigm \
    && make USE_PGXS=1 \
    && make USE_PGXS=1 install
    
RUN apt-get purge -y build-essential git postgresql-server-dev-16 \
    && apt-get autoremove -y 