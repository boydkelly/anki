FROM registry.fedoraproject.org/fedora-minimal:44

ENV PROXY_URL=http://localhost:3128

RUN rm -f \
  /etc/yum.repos.d/fedora-cisco-openh264.repo \
  /etc/yum.repos.d/fedora-updates-testing.repo && \
  sed -i \
  -e 's|^metalink=.*|#&|' \
  -e 's|^#baseurl=http://download.example/pub/fedora|baseurl=http://fedora.mirror.garr.it/mirrors/fedora|' \
  -e '/^countme=/d' \
  /etc/yum.repos.d/fedora.repo \
  /etc/yum.repos.d/fedora-updates.repo && \
  sed -i "/^\[main\]/a proxy=${PROXY_URL}" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a install_weak_deps=False" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a tsflags=nodocs" /etc/dnf/dnf.conf

RUN grep -R "baseurl\|metalink\|countme" /etc/yum.repos.d/

RUN microdnf install -y \
  python \
  python3-uv \
  qt6-qtwayland \
  nspr \
  nss \
  libxkbfile \
  alsa-lib \
  python3-decorator \
  mesa-vulkan-drivers && \
  microdnf clean all

# Unified working directory for both the uv project files and runtime data
WORKDIR /app

# Copy project definition and sync the environment
COPY pyproject.toml ./
RUN UV_PROJECT_ENVIRONMENT="/usr/local/anki" uv sync --no-cache

# Environment variables (Updated ANKI_BASE to point to our unified dir)
ENV ANKI_WAYLAND=1
ENV QTWEBENGINE_CHROMIUM_FLAGS="--no-sandbox --disable-features=Vulkan"
ENV QSG_RHI_BACKEND=opengl
ENV ANKI_BASE="/app/Anki2"
ENV PATH="/usr/local/anki/bin:$PATH"

# Script configuration
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["entrypoint.sh"]
CMD []
