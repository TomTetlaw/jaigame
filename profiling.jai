
pzone :: (name: string) #expand {
    `start := current_time_monotonic();
    `defer {
        `duration := to_float64_seconds(current_time_monotonic() - start);
        `log("duration for %: %", name, duration);
    };
}