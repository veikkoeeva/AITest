# 🏗️ Alpine PostgreSQL with PostGIS & pgvector

Here `.\start-aitest-postgres-container.ps1` builds an Alpine Linux and includes a PostgreSQL database with the following extensions installed:

- 🟢 **pgvector**
- 🗺️ **PostGIS**
- 🏞️ **PostGIS Raster**
- 🏙️ **PostGIS Topology**

## 🚀Features

- **🐦 Lightweight Alpine Base**  
  Alpine Linux for its small footprint, efficiency and increase security. Compared to the default PostGIS images (typically based on Debian or Ubuntu) compared to the default Postgres or PostGIS image.

- **📦Extensions Installed**  
  Once your container is running, you can enable the extensions in your database by executing:

  ```sql
  CREATE EXTENSION IF NOT EXISTS vector;
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE EXTENSION IF NOT EXISTS postgis_raster;
  CREATE EXTENSION IF NOT EXISTS postgis_topology;
  ```

## 🔐 A quick security options comparison for local and production deployments

| 🔒 **Security Method**    | 🔍 **Description**                                                                          | ✅ **Benefits**                                                          | ⚠️ **Considerations**                                                                | 🔒 **Security Level**  |
|--------------------------|----------------------------------------------------------------------------------------------|-------------------------------------------------------------------------|--------------------------------------------------------------------------------------|------------------------|
| 🔓 **Trust (Local Only)** | Allows any local user to connect **without a password**.                                    | ✅ Simple & easy for local development.                                 | ⚠️ **Not secure for production.**                                                     | 🔒                     |
| 🔑 **mTLS (Mutual TLS)**  | Uses **X.509 certificates** for **mutual authentication** between client & server.          | ✅ **Strong authentication**, encryption & integrity.                   | ⚠️ Requires **managing certificates**; setup is more complex.                         | 🔒🔒                   |
| 🔑 **OAuth (Token-Based)**| Uses **OAuth provider** (e.g., Google, Azure) to generate access tokens for authentication. | ✅ Fine-grained access control; **modern identity management**.         | ⚠️ Requires an **OAuth infrastructure**; more **complex to set up**.                  | 🔒🔒🔒                 |
| 🔑 **OAuth + mTLS**       | Combines **mTLS for authentication** and **OAuth for access control**.                      | ✅ **Strongest security**; **token rotation**; prevents replay attacks. | ⚠️ **Requires setting up both OAuth + mTLS**; advanced setup needed.                  | 🔒🔒🔒🔒               |
