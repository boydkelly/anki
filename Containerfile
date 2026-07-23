# ==========================================
# STAGE 1: Builder (Compiles C-extensions)
# ==========================================
FROM registry.fedoraproject.org/fedora-minimal:45 AS builder

ENV PROXY_URL=http://localhost:3128

ARG COUNTRY="fr"

RUN rm -f \
  /etc/yum.repos.d/fedora-cisco-openh264.repo \
  /etc/yum.repos.d/fedora-updates-testing.repo && \
  sed -i \
  -e 's|^metalink=https://|metalink=http://|' \
  -e "s|^metalink=.*|&\&country=${COUNTRY}\&protocol=http|" \
  -e '/^countme=/d' \
  /etc/yum.repos.d/fedora.repo \
  /etc/yum.repos.d/fedora-updates.repo && \
  sed -i "/^\[main\]/a proxy=${PROXY_URL}" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a install_weak_deps=False" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a tsflags=nodocs" /etc/dnf/dnf.conf

RUN microdnf install -y \
  gcc \
  python3-devel \
  python3-uv \
  && microdnf clean all \
  && sed -i '/^proxy=/d' /etc/dnf/dnf.conf

# Create venv explicitly linked to system python3 so the generated shebangs match Stage 2
RUN uv venv --python /usr/bin/python3 /usr/local/anki

# Compile dependencies for anki and aqt, excluding those packages themselves, and install them
RUN echo "anki" > /tmp/reqs.txt && \
  echo "aqt" >> /tmp/reqs.txt && \
  uv pip compile /tmp/reqs.txt -o /tmp/requirements.txt && \
  grep -Ev '^(anki|aqt)([=<>!~]|$)' /tmp/requirements.txt > /tmp/requirements-deps.txt && \
  uv pip install --python /usr/local/anki --no-cache -r /tmp/requirements-deps.txt

# ==========================================
# STAGE 2: Minimal Runtime Image
# ==========================================
FROM registry.fedoraproject.org/fedora-minimal:45

ENV PROXY_URL=http://localhost:3128

ARG COUNTRY="fr"

RUN rm -f \
  /etc/yum.repos.d/fedora-cisco-openh264.repo \
  /etc/yum.repos.d/fedora-updates-testing.repo && \
  sed -i \
  -e 's|^metalink=https://|metalink=http://|' \
  -e "s|^metalink=.*|&\&country=${COUNTRY}\&protocol=http|" \
  -e '/^countme=/d' \
  /etc/yum.repos.d/fedora.repo \
  /etc/yum.repos.d/fedora-updates.repo && \
  sed -i "/^\[main\]/a proxy=${PROXY_URL}" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a install_weak_deps=False" /etc/dnf/dnf.conf && \
  sed -i "/^\[main\]/a tsflags=nodocs" /etc/dnf/dnf.conf

RUN microdnf install -y \
  python3 \
  python3-uv \
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

COPY --from=builder /usr/local/anki /usr/local/anki

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
