String quantity(int value, String singular, String plural) =>
    '$value ${value == 1 ? singular : plural}';

String agreement(int value, String singular, String plural) =>
    value == 1 ? singular : plural;
