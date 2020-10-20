FROM --platform=$BUILDPLATFORM golang:1.15-buster AS src

ARG VERSION=v2.1.2
ARG BUILDPLATFORM

RUN git clone https://github.com/kubernetes-csi/external-snapshotter.git  /go/src/external-snapshotter

WORKDIR /go/src/external-snapshotter

RUN git checkout ${VERSION}
RUN go mod download

FROM --platform=$BUILDPLATFORM src AS builder

ARG TARGETPLATFORM
ARG BUILDPLATFORM

RUN GOOS=$(echo $TARGETPLATFORM | cut -f1 -d/) && \
    GOARCH=$(echo $TARGETPLATFORM | cut -f2 -d/) && \
    GOARM=$(echo $TARGETPLATFORM | cut -f3 -d/ | sed "s/v//" ) && \
    CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} GOARM=${GOARM} go build -a -installsuffix cgo -ldflags '-X main.version=$(REV) -extldflags "-static"' ./cmd/csi-snapshotter


FROM gcr.io/distroless/static

COPY --from=builder /go/src/external-snapshotter/csi-snapshotter /bin/csi-snapshotter

USER 1234:1234

ENTRYPOINT ["/bin/csi-snapshotter"]
