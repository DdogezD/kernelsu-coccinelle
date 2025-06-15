**Supported Linux kernels: 3.4 to 5.10**

Alternative manual hooks from @backslashxx that are designed to minimize the number of common code paths that are hooked in order to reduce their performance impact (though nobody proved that the original hooks have any significant perf impact AFAIK…)

They are based on https://github.com/backslashxx/KernelSU/issues/5

**Note**: Don't apply the patches from the parent directory if you use the patches from this folder! They are standalone and shouldn't be combined with the other ones.

# How to use

1) Install [Coccinelle](https://coccinelle.gitlabpages.inria.fr/website/download.html).
2) Run this:

```sh
./apply.sh /path/to/your/kernel/source
```
