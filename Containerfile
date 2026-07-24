FROM registry.fedoraproject.org/fedora-minimal:45

ENV PROXY_URL=http://localhost:3128
ARG COUNTRY="fr"

# Optimize repository configurations
RUN rm -f \
  /etc/yum.repos.d/fedora-cisco-openh264.repo \
  /etc/yum.repos.d/fedora-updates-testing.repo && \
  sed -i \
  -e 's|^metalink=https://|metalink=http://|' \
  -e "s|^metalink=.*|&\&country=${COUNTRY}\&protocol=http|" \
  -e '/^countme=/d' \
  /etc/yum.repos.d/*.repo && \
  sed -i "/^\[main\]/a proxy=${PROXY_URL}" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a install_weak_deps=False" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a tsflags=nodocs" /etc/dnf/dnf.conf

# Install runtime requirements AND pre-compiled system Python packages (No GCC/development tools needed!)
RUN microdnf install -y \
  python3 \
  python3-uv \
  python3-pyqt6 \
  python3-pyqt6-sip \
  python3-pyqt6-webengine \
  python3-markupsafe \
  python3-markdown \
  python3-orjson \
  python3-cryptography \
  python3-zstandard \
  python3-protobuf \
  python3-truststore \
  qt6-qtwayland \
  nspr \
  nss \
  libxkbfile \
  alsa-lib \
  mpv \
  python3-decorator \
  mesa-vulkan-drivers && \
  microdnf clean all && \
  sed -i '/^proxy=/d' /etc/dnf/dnf.conf

# Create the virtual environment with access to system site-packages
RUN uv venv --python /usr/bin/python3 --system-site-packages /usr/local/anki

# Compile dependencies, and filter out all system-installed C-extensions so we never compile from PyPI
RUN echo "anki" > /tmp/reqs.txt && \
  echo "aqt" >> /tmp/reqs.txt && \
  uv pip compile /tmp/reqs.txt -o /tmp/requirements.txt && \
  # Filter out system C-extension dependencies (prefix matching automatically handles pyqt6, pyqt6-sip, pyqt6-qt6, pyqt6-webengine, pyqt6-webengine-qt6, etc.)
  grep -Eiv '^(anki|aqt|pyqt6|markupsafe|orjson|cryptography|zstandard|protobuf|truststore)' /tmp/requirements.txt > /tmp/requirements-deps.txt && \
  # Install only pure-Python dependencies from PyPI, explicitly disallowing compilation and ignoring dependency resolution since the requirements file already has the full resolved flat list
  uv pip install --python /usr/local/anki --no-cache --no-build --no-deps -r /tmp/requirements-deps.txt

WORKDIR /app

ENV ANKI_WAYLAND=1
ENV QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-features=Vulkan"
ENV QSG_RHI_BACKEND=opengl
ENV ANKI_BASE="/app/Anki2"
ENV PATH="/usr/local/anki/bin:$PATH"

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD []
