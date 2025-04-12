# Define the PostgreSQL major version as a build argument.
# This is needed in library paths and to select the Debian image
# for building extensions and to run PostgreSQL with PostGIS.
ARG PG_MAJOR=17

# ---- Builder Stage ---- #
FROM postgis/postgis:${PG_MAJOR}-3.5 AS builder

# Install required build dependencies for Debian
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        ca-certificates \
        postgresql-server-dev-${PG_MAJOR} \
        clang \
        llvm \
        cmake \
        ninja-build \
        liblz4-dev \
        zlib1g-dev \
        curl \
        wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

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

# ---- Base Image Stage ---- #
FROM postgis/postgis:${PG_MAJOR}-3.5 AS base

# Create target directories for extensions
# These are the standard Debian PostgreSQL paths
RUN mkdir -p /usr/lib/postgresql/${PG_MAJOR}/lib && \
    mkdir -p /usr/share/postgresql/${PG_MAJOR}/extension && \
    mkdir -p /var/lib/postgresql/duckdb_extensions

# Copy the staged shared library, control file, and SQL file(s) to the appropriate locations
COPY --from=builder /tmp/pgvector_files/vector.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /tmp/pgvector_files/vector.control /usr/share/postgresql/${PG_MAJOR}/extension/
COPY --from=builder /tmp/pgvector_files/vector--*.sql /usr/share/postgresql/${PG_MAJOR}/extension/

# Copy pg_duckdb files directly to their final destinations
COPY --from=builder /tmp/pg_duckdb_files/pg_duckdb.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /tmp/pg_duckdb_files/libduckdb.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /tmp/pg_duckdb_files/pg_duckdb.control /usr/share/postgresql/${PG_MAJOR}/extension/
COPY --from=builder /tmp/pg_duckdb_files/pg_duckdb--*.sql /usr/share/postgresql/${PG_MAJOR}/extension/

# Ensure PostgreSQL data directory is correctly owned and secured.
RUN mkdir -p /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chmod 700 /var/lib/postgresql/data

# Switch to the non-root user (just in case).
USER postgres

# ---- Configured Stage ---- #
FROM base AS configured

USER root

RUN mkdir -p /docker-entrypoint-initdb.d


USER postgres

# ---- Production Stage ---- #
FROM configured AS production
CMD ["postgres"]

# ---- Development Stage ---- #
FROM configured AS dev

# Copy the entrypoint script before switching users
COPY --chmod=0755 dev-entrypoint.sh /dev-entrypoint.sh

USER root
RUN sed -i 's/\r$//' /dev-entrypoint.sh

USER postgres
ENTRYPOINT ["/dev-entrypoint.sh"]