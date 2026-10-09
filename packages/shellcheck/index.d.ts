/** The ShellCheck version this package runs (the upstream version, without any -r.N re-pack suffix). */
export declare const version: string;

/** Absolute path of the native shellcheck binary for this platform. Throws if it is not installed. */
export declare function binaryPath(): string;
