python \
    -m build \
    --wheel \
    --outdir dist \
    --no-isolation \
    --skip-dependency-check \
    "-C--global-option=build_ext" \
    "-C--global-option=--no-cmake-extension=all" \
    ./
pip install --no-deps dist/*.whl
