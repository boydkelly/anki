---

# Anki in a container

1)  Build the container:  podman build -t anki-pre .

2)  Run/install:   ./anki-pre install

The image will automatically mount $HOME/.local/share/Anki2 under /root/ inside the image,
so you can copy your existing profile into the image.

Note:  The specfile here builds an rpm but is not used or needed by the container.
