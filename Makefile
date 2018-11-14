

		
amd64:
		cp Dockerfile.cross Dockerfile.amd64
		sed -i "s|__BASEIMAGE_ARCH__|amd64|g" Dockerfile.amd64
		sed -i "s|__QEMU_ARCH__|x86_64|g" Dockerfile.amd64
		sed -i "/__CROSS_/d" Dockerfile.amd64
		cat Dockerfile.amd64
		docker build -f Dockerfile.amd64 -t $(REPO)/$(IMAGE_NAME):amd64 .
  		docker push $(REPO)/$(IMAGE_NAME):amd64

arm64v8:
		cp Dockerfile.cross Dockerfile.arm64v8
		sed -i "s|__BASEIMAGE_ARCH__|arm64v8|g" Dockerfile.arm64v8
		sed -i "s|__QEMU_ARCH__|aarch64|g" Dockerfile.arm64v8
		sed -i  "s/__CROSS_//g" Dockerfile.arm64v8
		cat Dockerfile.arm64v8
		wget https://github.com/multiarch/qemu-user-static/releases/download/v2.12.0/qemu-aarch64-static
		chmod 755 qemu-aarch64-static
		docker build --build-arg ARCH=arm64v8 --no-cache -f Dockerfile.arm64v8 -t $(REPO)/$(IMAGE_NAME):arm64v8 .
  		docker push $(REPO)/$(IMAGE_NAME):arm64v8

arm32v7:
		cp Dockerfile.cross Dockerfile.arm32v7
		sed -i "s|__BASEIMAGE_ARCH__|arm32v7|g" Dockerfile.arm32v7
		sed -i "s|__QEMU_ARCH__|arm|g" Dockerfile.arm32v7
		sed -i  "s/__CROSS_//g" Dockerfile.arm32v7
		cat Dockerfile.arm32v7
		wget https://github.com/multiarch/qemu-user-static/releases/download/v2.12.0/qemu-arm-static
		chmod 755 qemu-arm-static 
		docker build --build-arg ARCH=arm32v7 --no-cache -f Dockerfile.arm32v7 -t $(REPO)/$(IMAGE_NAME):arm32v7 .
  		docker push $(REPO)/$(IMAGE_NAME):arm32v7
