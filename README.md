# platform-test

This repo is used to test the platform.

## Contents

This repo consists of a Makefile called `platform-test.make`. We avoided calling it `Makefile` in order to avoid conflicting with the Makefile that is copied over from [template-infra](https://github.com/navapbc/template-infra) when installing the template infrastructure.

## Usage

Test installing template infrastructure

```bash
make -f platform-test.make install-infra
```

Test installing NextJS application template

```bash
make -f platform-test.make install-application-nextjs
```

Cleanup after testing

```bash
make -f platform-test.make clean
```
