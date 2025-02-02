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
        llvm19

# Clone and build pgvector.
RUN git clone https://github.com/pgvector/pgvector.git /tmp/pgvector && \
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

# Second stage: base image.
FROM postgis/postgis:${PG_MAJOR}-3.5-alpine AS base

# Create target directories for the shared library, control file and SQL files.
RUN mkdir -p /usr/lib/postgresql/17/lib && \
    mkdir -p /usr/share/postgresql/extension

# Copy the staged shared library, control file, and SQL file(s) to a known location...
COPY --from=builder /tmp/pgvector_files/vector.so /usr/local/lib/postgresql/
COPY --from=builder /tmp/pgvector_files/vector.control /usr/local/share/postgresql/extension/
COPY --from=builder /tmp/pgvector_files/vector--*.sql /usr/local/share/postgresql/extension/

# Ensure PostgreSQL data directory is correctly owned and secured.
RUN mkdir -p /var/lib/postgresql/data \
    && chown -R postgres:postgres /var/lib/postgresql \
    && chmod 700 /var/lib/postgresql/data

# Copy the entrypoint script before switching users. This syntax needs permissions in hexadecimal.
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

# Switch to the non-root user (just in case).
USER postgres

# Production Stage: Default PostgreSQL setup.
FROM base AS production
CMD ["postgres"]

# Development Stage: Custom authentication settings.
FROM base AS dev
ENTRYPOINT ["/entrypoint.sh"]