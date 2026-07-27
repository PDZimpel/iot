# Configures and builds the project
set -euo pipefail

SOURCE_DIR="/workspace"
BUILD_DIR="/workspace/build-docker"

cmake \
  -S "${SOURCE_DIR}" \
  -B "${BUILD_DIR}" \
  -G Ninja \
  -DCMAKE_MAKE_PROGRAM="$(command -v ninja)" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_TOOLCHAIN_FILE="${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake" \
  -DCMAKE_CUDA_FLAGS="--allow-unsupported-compiler"

cmake --build "${BUILD_DIR}" --parallel "$(nproc)"

echo "Build finished successfully. Binaries are under ${BUILD_DIR} (visible on the host too, via the bind mount)."
