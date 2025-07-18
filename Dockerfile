# syntax=docker/dockerfile:1

FROM python:3.12-slim AS builder

WORKDIR /app

# Install Poetry via pipx for reproducible builds
ENV PATH=/root/.local/bin:$PATH
RUN pip install --no-cache-dir pipx && \
    pipx install poetry

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends git && \
    rm -rf /var/lib/apt/lists/*

# Copy dependency descriptors first for layer caching
COPY pyproject.toml poetry.lock ./
# 新增：将 Git 历史复制进镜像，供 poetry-dynamic-versioning 读取
COPY .git ./

# Install project dependencies inside an in-project virtualenv
RUN poetry self add poetry-dynamic-versioning && \
    poetry config virtualenvs.in-project true && \
    poetry install --no-interaction --no-ansi --only main

# Copy project source code
COPY . .

# Clean up unnecessary data to keep image slim
RUN rm -rf .git

############################
# Runtime stage            #
############################
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copy the virtual environment and application code from builder stage
COPY --from=builder /app /app

# Expose a volume for input videos and output metadata (optional)
VOLUME ["/video", "/output"]

# Default command – can be overridden at runtime
ENTRYPOINT ["/app/.venv/bin/javsp"]
CMD ["-i", "/video"]