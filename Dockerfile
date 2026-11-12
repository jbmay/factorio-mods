FROM python:3.13-slim-bookworm

# Python's standard library handles HTTP and archive operations. Lua is used for
# syntax checks; the C++ runtime supports the downloaded Linux Factorio binary.
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
        ca-certificates \
        libstdc++6 \
        lua5.2 \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/tmp \
    LUAC=luac5.2

COPY tools/run_container_tests.py /usr/local/bin/run-container-tests.py

WORKDIR /workspace
ENTRYPOINT ["python", "/usr/local/bin/run-container-tests.py"]
