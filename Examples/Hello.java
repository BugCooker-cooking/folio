package com.example.folio;

import java.util.List;
import java.util.stream.Collectors;

/**
 * A small Java sample for Folio.
 */
@Deprecated
public final class Hello {
    private static final int MAX_NAMES = 3;

    public static void main(String[] args) {
        List<String> names = List.of("Ada", "Linus", "Grace", "Margaret");
        System.out.println(greet(names));
    }

    static String greet(List<String> names) {
        // Keep the first few names and build a greeting.
        return names.stream()
            .limit(MAX_NAMES)
            .map(name -> "Hello, " + name + "!")
            .collect(Collectors.joining("\n"));
    }
}
