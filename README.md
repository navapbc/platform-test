# platform-test

This repo is used to test the platform.

## Contents

This repo consists of a Makefile called `platform-test.mak`. We avoided calling it `Makefile` in order to avoid conflicting with the Makefile that is copied over from [template-infra](https://github.com/navapbc/template-infra) when installing the template infrastructure.

## Environment URLs

* [Dev environment](https://platform-test-dev.navateam.com/)

## Usage

Test installing template infrastructure

```bash
make -f platform-test.mak install-infra
```

Test installing NextJS application template

```bash
make -f platform-test.mak install-application-nextjs
```

Test installing Flask application template

```bash
make -f platform-test.mak install-application-flask
```

Cleanup after testing

```bash
make -f platform-test.mak clean
```
