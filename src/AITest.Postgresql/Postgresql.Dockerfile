# Define the PostgreSQL major version as a build argument.
# This is needed in library paths and to select the Alpine image
# for building extensions and to run PostgreSQL with PostGIS.
ARG PG_MAJOR=17

FROM postgis/postgis:${PG_MAJOR}-3.5-alpine AS builder

# Alpine image uses apk instead of apt-get and needs more libraries
# to compile the pgvector extension. This is a node IF one were to change
# this to the default image that needs needs libraries.
RUN apk update && \
    apk add --no-cache \
        build-base \
        git \
        ca-certificates \
        postgresql-dev \
        clang19 \
        llvm19 \
        cmake \
        ninja \
        gcompat

# ---- Build and set up pgvector extension ---- #

# Clone and build pgvector.
RUN git clone --depth 1 --branch v0.8.0 https://github.com/pgvector/pgvector.git /tmp/pgvector && \
    cd /tmp/pgvector && \
    make clean && \
    make OPTFLAGS="" && \
    make install

# Stage the installed files to a fixed, known location.
# - Copy the shared library from the installed pkglibdir.
# - Copy the SQL file(s) from the installed sharedir.
# - Copy the control file directly from the repository.
RUN mkdir -p /tmp/pgvector_files && \
    cp $(pg_config --pkglibdir)/vector.so /tmp/pgvector_files/ && \
    cp $(pg_config --sharedir)/extension/vector* /tmp/pgvector_files/ || true && \
    cp /tmp/pgvector/vector.control /tmp/pgvector_files/


# ---- Build and set up pg_duckdb extension ---- #

# Clone and build pg_duckdb.
RUN git clone --depth 1 --recurse-submodules --branch v0.3.1 https://github.com/duckdb/pg_duckdb.git /tmp/pg_duckdb && \
cd /tmp/pg_duckdb && \
make clean && \
make OPTFLAGS="" && \
make install

# Create a known location to stage files
RUN mkdir -p /tmp/pg_duckdb_files && \
cp $(pg_config --pkglibdir)/pg_duckdb.so /tmp/pg_duckdb_files/ && \
cp /tmp/pg_duckdb/third_party/duckdb/build/release/src/libduckdb.so /tmp/pg_duckdb_files/ && \
cp $(pg_config --sharedir)/extension/pg_duckdb* /tmp/pg_duckdb_files/ || true && \
cp /tmp/pg_duckdb/pg_duckdb.control /tmp/pg_duckdb_files/

# Second stage: base image.
FROM postgis/postgis:${PG_MAJOR}-3.5-alpine AS base

# Create target directories for the shared library, control file and SQL files.
RUN mkdir -p /usr/lib/postgresql/17/lib && \
    mkdir -p /usr/share/postgresql/extension

# Copy the staged shared library, control file, and SQL file(s) to a known location...
COPY --from=builder /tmp/pgvector_files/vector.so /usr/local/lib/postgresql/
COPY --from=builder /tmp/pgvector_files/vector.control /usr/local/share/postgresql/extension/
COPY --from=builder /tmp/pgvector_files/vector--*.sql /usr/local/share/postgresql/extension/

COPY --from=builder /tmp/pg_duckdb_files/pg_duckdb.so /usr/local/lib/postgresql/
COPY --from=builder /tmp/pg_duckdb_files/libduckdb.so /usr/local/lib/
COPY --from=builder /tmp/pg_duckdb_files/pg_duckdb.control /usr/local/share/postgresql/extension/
COPY --from=builder /tmp/pg_duckdb_files/pg_duckdb--*.sql /usr/local/share/postgresql/extension/

# Ensure PostgreSQL data directory is correctly owned and secured.
RUN mkdir -p /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chmod 700 /var/lib/postgresql/data

# Switch to the non-root user (just in case).
USER postgres

FROM base AS configured

# Ensure root privileges to modify system config.
USER root
RUN echo "shared_preload_libraries = 'pg_duckdb'" >> /usr/local/share/postgresql/postgresql.conf.sample

USER postgres

# Production Stage: Default PostgreSQL setup.
FROM configured AS production
CMD ["postgres"]

# Development Stage: Custom authentication settings.
FROM configured AS dev

# Copy the entrypoint script before switching users. This syntax needs permissions in hexadecimal.
COPY --chmod=0755 dev-entrypoint.sh /dev-entrypoint.sh

USER root
RUN sed -i 's/\r$//' /dev-entrypoint.sh

USER postgres
ENTRYPOINT ["/dev-entrypoint.sh"]