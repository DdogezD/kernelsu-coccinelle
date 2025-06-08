// Coccinelle scope-minimized patches for KernelSU
// From: https://github.com/backslashxx/KernelSU/issues/5#issuecomment-2878532104


// File: fs/exec.c
// Adds hook to asmlinkage int sys_execve()

@do_execve_hook_minimized depends on file in "exec.c"@
identifier filenam, __argv, __envp;
identifier argv, envp;
type T1, T2;
attribute name __read_mostly;
@@

+#ifdef CONFIG_KSU
+extern bool ksu_execveat_hook __read_mostly;
+extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
+			void *envp, int *flags);
+extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,
+				 void *argv, void *envp, int *flags);
+#endif
do_execve(struct filename *filenam, T1 __argv, T2 __envp) {
 	struct user_arg_ptr argv = { .ptr.native = __argv };
 	struct user_arg_ptr envp = { .ptr.native = __envp };
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_execveat_hook))
+		ksu_handle_execveat((int *)AT_FDCWD, &filenam, &argv, &envp, 0);
+	else
+		ksu_handle_execveat_sucompat((int *)AT_FDCWD, &filenam, NULL, NULL, NULL);
+#endif
...
}

@compat_do_execve_hook_minimized depends on file in "exec.c"@
identifier filenam, argv, envp;
@@

compat_do_execve(struct filename *filenam, ...) {
...
+#ifdef CONFIG_KSU // 32-bit su, 32-on-64 ksud support
+	if (unlikely(ksu_execveat_hook))
+		ksu_handle_execveat((int *)AT_FDCWD, &filenam, &argv, &envp, 0);
+	else
+		ksu_handle_execveat_sucompat((int *)AT_FDCWD, &filenam, NULL, NULL, NULL);
+#endif
 	return do_execveat_common(AT_FDCWD, filenam, argv, envp, 0);
}

// Alternative for Linux <= 3.4
// File arch/arm/kernel/sys_arm.c
// Adds hook to asmlinkage int sys_execve()
@do_execve_hook_minimized_alternative depends on file in "sys_arm.c" && never do_execve_hook_minimized@
identifier filenamei, argv, envp;
identifier error, filenam;
type T1;
attribute name __user, __read_mostly;
@@

+#ifdef CONFIG_KSU
+extern bool ksu_execveat_hook __read_mostly;
+extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
+ 			void *envp, int *flags);
+extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,
+ 				 void *argv, void *envp, int *flags);
+#endif
sys_execve(T1 filenamei, const char __user *const __user *argv, const char __user *const __user *envp, ...) {
	int error;
	struct filename *filenam;

	filenam = getname(filenamei);
	error = PTR_ERR(filenam);
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_execveat_hook))
+		ksu_handle_execveat((int *)AT_FDCWD, &filenam, &argv, &envp, 0);
+	else
+		ksu_handle_execveat_sucompat((int *)AT_FDCWD, &filenam, NULL, NULL, NULL);
+#endif
...
}

// Another alternative for Linux <= 3.4 (char * instead of struct filename *)
// File arch/arm/kernel/sys_arm.c
// Adds hook to asmlinkage int sys_execve()
@do_execve_hook_minimized_alternative2 depends on file in "sys_arm.c" && never do_execve_hook_minimized@
identifier filenamei, argv;
identifier error, filename;
type T1;
attribute name __user, __read_mostly;
@@

+#ifdef CONFIG_KSU
+extern bool ksu_execveat_hook __read_mostly;
+extern int ksu_handle_execve_sucompat(int *fd, const char __user **filename_user,
+			       void *__never_use_argv, void *__never_use_envp,
+			       int *__never_use_flags);
+extern int ksu_handle_execve_ksud(const char __user *filename_user,
+			const char __user *const __user *__argv);
+#endif

sys_execve(T1 filenamei, const char __user *const __user *argv, ...) {
	int error;
	char *filename;

	filename = getname(filenamei);
	error = PTR_ERR(filename);

+#ifdef CONFIG_KSU
+	if (unlikely(ksu_execveat_hook))
+		ksu_handle_execve_ksud(filename, argv);
+	else
+		ksu_handle_execve_sucompat((int *)AT_FDCWD, &filename, NULL, NULL, NULL);
+#endif
...
}

// Alternative for Linux 3.10
// File exec.c
// Adds hook to SYSCALL_DEFINE3(execve, ...).
@do_execve_hook_minimized_alternative3_1 depends on file in "exec.c" && never do_execve_hook_minimized && never do_execve_hook_minimized_alternative && never do_execve_hook_minimized_alternative2@
identifier filenam, argv, envp;
identifier path, error;
type T1;
attribute name __user, __read_mostly;
@@

+#ifdef CONFIG_KSU
+extern bool ksu_execveat_hook __read_mostly;
+extern int ksu_handle_execveat(int *fd, struct filename **filename_ptr, void *argv,
+			void *envp, int *flags);
+extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename_ptr,
+				 void *argv, void *envp, int *flags);
+#endif
execve(T1 filenam, const char __user *const __user *argv, const char __user *const __user *envp) {
	struct filename *path = getname(filenam);
	int error = PTR_ERR(path);
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_execveat_hook))
+		ksu_handle_execveat((int *)AT_FDCWD, &path, &argv, &envp, 0);
+	else
+		ksu_handle_execveat_sucompat((int *)AT_FDCWD, &path, NULL, NULL, NULL);
+#endif
...
}

// Second part of alternative for Linux 3.10
@do_execve_hook_minimized_alternative3_2 depends on do_execve_hook_minimized_alternative3_1 exists@
identifier filenam, error;
identifier path;
type T1;
@@
compat_sys_execve(T1 filenam, ...) {
	struct filename *path = getname(filenam);
	int error = PTR_ERR(path);
...
+#ifdef CONFIG_KSU
+	if (!ksu_execveat_hook)
+		ksu_handle_execveat_sucompat((int *)AT_FDCWD, &path, NULL, NULL, NULL); /* 32-bit su */
+#endif
error = compat_do_execve(...);
...
}

// File: fs/open.c
// Adds hook to SYSCALL_DEFINE3(faccessat, ...).

@sys_faccessat_hook_minimized depends on file in "open.c"@
identifier dfd, filename, mode;
attribute name __user;
@@

+#ifdef CONFIG_KSU
+extern int ksu_handle_faccessat(int *dfd, const char __user **filename_user, int *mode,
+			                    int *flags);
+#endif
faccessat(int dfd, const char __user *filename, int mode) {
+#ifdef CONFIG_KSU
+	ksu_handle_faccessat(&dfd, &filename, &mode, NULL);
+#endif
...
}

// File: fs/read_write.c
// Adds hook to SYSCALL_DEFINE3(read, ...).

@sys_read_hook_minimized depends on file in "read_write.c" exists@
identifier fd, buf, count, ret, pos;
attribute name __user, __read_mostly;
@@

+#ifdef CONFIG_KSU
+extern bool ksu_vfs_read_hook __read_mostly;
+extern int ksu_handle_sys_read(unsigned int fd, char __user **buf_ptr,
+			size_t *count_ptr);
+#endif
read(unsigned int fd, char __user *buf, size_t count) {
...
(
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_vfs_read_hook))
+		ksu_handle_sys_read(fd, &buf, &count);
+#endif
  return ksys_read(fd, buf, count);
|
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_vfs_read_hook))
+		ksu_handle_sys_read(fd, &buf, &count);
+#endif
  ret = vfs_read(..., buf, count, &pos);
)
...
}

// File: fs/stat.c
// Adds hook to SYSCALL_DEFINE4(newfstatat, ...)

@sys_newfstatat_hook_minimized depends on file in "stat.c" exists@
identifier dfd, filename, flag, error, stat;
attribute name __user;
@@

+#ifdef CONFIG_KSU
+extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
+#endif
newfstatat(int dfd, const char __user *filename, ..., int flag) {
...
+#ifdef CONFIG_KSU
+	ksu_handle_stat(&dfd, &filename, &flag);
+#endif
error = vfs_fstatat(dfd, filename, &stat, flag);
...
}

// File: fs/stat.c
// Adds hook to SYSCALL_DEFINE4(fstatat64, ...).

@sys_fstatat64_hook_minimized depends on file in "stat.c" exists@
identifier dfd, filename, stat, flag, error;
attribute name __user;
@@

+#ifdef CONFIG_KSU
+extern int ksu_handle_stat(int *dfd, const char __user **filename_user, int *flags);
+#endif
fstatat64(int dfd, const char __user *filename, ..., int flag) {
...
+#ifdef CONFIG_KSU // 32-bit su
+	ksu_handle_stat(&dfd, &filename, &flag);
+#endif
error = vfs_fstatat(dfd, filename, &stat, flag);
...
}

// File: drivers/input/input.c
// Adds hook to input_event(...).

@input_event_hook_minimized depends on file in "input.c"@
identifier dev, typ, code, value;
attribute name __read_mostly;
@@

+#ifdef CONFIG_KSU
+extern bool ksu_input_hook __read_mostly;
+extern int ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);
+#endif
input_event(struct input_dev *dev, unsigned int typ, unsigned int code, int value) {
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_input_hook))
+		ksu_handle_input_handle_event(&typ, &code, &value);
+#endif
...
}

// Alternative for Linux >= 5.4
// File: drivers/input/input.c
// Adds hook to input_handle_event(...).

@input_event_hook_minimized_alternative depends on file in "input.c" && never input_event_hook_minimized@
identifier dev, typ, code, value;
attribute name __read_mostly;
@@

+#ifdef CONFIG_KSU
+extern bool ksu_input_hook __read_mostly;
+extern int ksu_handle_input_handle_event(unsigned int *type, unsigned int *code, int *value);
+#endif
input_handle_event(struct input_dev *dev, unsigned int typ, unsigned int code, int value) {
+#ifdef CONFIG_KSU
+	if (unlikely(ksu_input_hook))
+		ksu_handle_input_handle_event(&typ, &code, &value);
+#endif
...
}


// File: drivers/tty/pty.c
// Adds hook to pts_unix98_lookup(...) with struct file* parameter.

@pts_unix98_lookup_file_hook_minimized depends on file in "pty.c"@
identifier file;
@@

+#ifdef CONFIG_KSU
+extern int ksu_handle_devpts(struct inode*);
+#endif
pts_unix98_lookup(..., struct file *file, ...) {
+#ifdef CONFIG_KSU
+	ksu_handle_devpts((struct inode *)file->f_path.dentry->d_inode);
+#endif
...
}

// File: drivers/tty/pty.c
// Adds hook to pts_unix98_lookup(...) with struct inode* parameter.

@pts_unix98_lookup_file_hook_minimized_alternative depends on file in "pty.c"@
identifier pts_inode;
@@

+#ifdef CONFIG_KSU
+extern int ksu_handle_devpts(struct inode*);
+#endif
pts_unix98_lookup(..., struct inode *pts_inode, ...) {
+#ifdef CONFIG_KSU
+	ksu_handle_devpts(pts_inode);
+#endif
...
}

// Alternative for Linux >= 5.4
// File: fs/devpts/inode.c
// Adds hook to devpts_get_priv(...).

@devpts_get_priv depends on file in "inode.c"@
identifier dentry;
@@

+#ifdef CONFIG_KSU
+extern int ksu_handle_devpts(struct inode*);
+#endif
devpts_get_priv(struct dentry *dentry) {
+#ifdef CONFIG_KSU
+	ksu_handle_devpts(dentry->d_inode);
+#endif
...
}

// File: include/linux/cred.h
@has_get_cred_rcu depends on file in "include/linux/cred.h"@
@@
get_cred_rcu(const struct cred *cred) { ... }

// File: include/linux/cred.h
// Backport for Linux < 5.0
@get_cred_rcu_h depends on file in "include/linux/cred.h" && never has_get_cred_rcu@
@@

get_cred(...) { ... }

+static inline const struct cred *get_cred_rcu(const struct cred *cred)
+{
+	struct cred *nonconst_cred = (struct cred *) cred;
+	if (!cred)
+		return NULL;
+#ifdef atomic_inc_not_zero
+	if (!atomic_inc_not_zero(&nonconst_cred->usage))
+		return NULL;
+#else
+	if (!atomic_long_inc_not_zero(&nonconst_cred->usage))
+		return NULL;
+#endif
+	validate_creds(cred);
+	return cred;
+}

// File: kernel/cred.c
// Backport for Linux < 5.0
@get_cred_rcu depends on file in "cred.c"@
identifier atomic_inc_not_zero =~ "atomic_inc_not_zero|atomic_long_inc_not_zero";
@@

get_task_cred(...) {
...
do { ... } while (
-!atomic_inc_not_zero(&((struct cred *)cred)->usage)
+!get_cred_rcu(cred)
	);
...
}