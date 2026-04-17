ARG UBUNTU_VERSION="24.04"
FROM crazymax/osxcross:latest-ubuntu AS source 
# crazymax/osxcross:latest-ubuntu need ubuntu:24.04
FROM --platform=$BUILDPLATFORM ubuntu:${UBUNTU_VERSION} AS test-ubuntu
RUN export DEBIAN_FRONTEND="noninteractive" && apt-get update && apt-get install -y clang file
FROM test-ubuntu AS final
ENV PATH="/osxcross/bin:$PATH"
ENV LD_LIBRARY_PATH="/osxcross/lib:$LD_LIBRARY_PATH"
COPY --link --from=source /osxcross /osxcross
CMD ["/bin/bash"]
