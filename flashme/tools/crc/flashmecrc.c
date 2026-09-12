/*
 * flashmecrc.c
 *
 * Small, dependency-free verifier for the FlashMe reconstruction tree.
 * It deliberately reads images without modifying them.  Retail Nintendo
 * firmware CRC-32 checks normalize the private Wi-Fi calibration range in
 * memory; FlashMe CRC-16 checks use the published image's own checksum span.
 */

#include <errno.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define NINTENDO_FIRMWARE_BYTES 0x40000u

typedef struct FileData {
    unsigned char *bytes;
    size_t size;
} FileData;

typedef struct Arguments {
    const char *mode;
    const char *image_path;
    const char *reference_path;
    const char *range_end_text;
    const char *expected_text;
    const char *fill_start_text;
    const char *fill_end_text;
    const char *write_path;
} Arguments;

static void usage(const char *program)
{
    fprintf(stderr,
            "Usage:\n"
            "  %s crc32-official --image FILE --range-end N --private-fill-start N\n"
            "      --private-fill-end N --expected N --write FILE\n"
            "  %s crc16-flashme --image FILE --reference FILE --range-end N\n"
            "      --expected N --write FILE\n"
            "  %s crc16-record --image FILE --range-end N --write FILE\n"
            "\n"
            "All numeric values accept decimal or 0x-prefixed hexadecimal notation.\n",
            program, program, program);
}

static int parse_u32(const char *text, uint32_t *value)
{
    char *end = NULL;
    unsigned long long parsed;

    if (text == NULL || *text == '\0' || *text == '-') {
        return 0;
    }

    errno = 0;
    parsed = strtoull(text, &end, 0);
    if (errno != 0 || end == text || *end != '\0' || parsed > UINT32_MAX) {
        return 0;
    }

    *value = (uint32_t)parsed;
    return 1;
}

static int read_file(const char *path, FileData *file)
{
    FILE *stream;
    long length;
    size_t read_size;

    file->bytes = NULL;
    file->size = 0;

    stream = fopen(path, "rb");
    if (stream == NULL) {
        fprintf(stderr, "error: cannot open '%s': %s\n", path, strerror(errno));
        return 0;
    }

    if (fseek(stream, 0, SEEK_END) != 0 || (length = ftell(stream)) < 0 ||
        fseek(stream, 0, SEEK_SET) != 0) {
        fprintf(stderr, "error: cannot determine the size of '%s'\n", path);
        fclose(stream);
        return 0;
    }

    if ((unsigned long long)length > SIZE_MAX) {
        fprintf(stderr, "error: '%s' is too large\n", path);
        fclose(stream);
        return 0;
    }

    file->size = (size_t)length;
    file->bytes = (unsigned char *)malloc(file->size == 0 ? 1 : file->size);
    if (file->bytes == NULL) {
        fprintf(stderr, "error: out of memory while reading '%s'\n", path);
        fclose(stream);
        return 0;
    }

    read_size = fread(file->bytes, 1, file->size, stream);
    if (read_size != file->size || ferror(stream)) {
        fprintf(stderr, "error: cannot read '%s'\n", path);
        free(file->bytes);
        file->bytes = NULL;
        file->size = 0;
        fclose(stream);
        return 0;
    }

    fclose(stream);
    return 1;
}

static void free_file(FileData *file)
{
    free(file->bytes);
    file->bytes = NULL;
    file->size = 0;
}

static uint32_t crc32_iso_hdlc(const unsigned char *bytes, size_t count,
                               uint32_t fill_start, uint32_t fill_end)
{
    uint32_t crc = UINT32_C(0xFFFFFFFF);
    size_t index;

    for (index = 0; index < count; ++index) {
        uint32_t byte = (index >= fill_start && index < fill_end) ? 0xFFu : bytes[index];
        unsigned int bit;

        crc ^= byte;
        for (bit = 0; bit < 8; ++bit) {
            crc = (crc & 1u) ? ((crc >> 1) ^ UINT32_C(0xEDB88320)) : (crc >> 1);
        }
    }

    return ~crc;
}

static uint16_t crc16_ibm(const unsigned char *bytes, size_t count)
{
    uint16_t crc = UINT16_C(0xFFFF);
    size_t index;

    for (index = 0; index < count; ++index) {
        unsigned int bit;

        crc = (uint16_t)(crc ^ bytes[index]);
        for (bit = 0; bit < 8; ++bit) {
            crc = (crc & 1u) ? (uint16_t)((crc >> 1) ^ UINT16_C(0xA001))
                             : (uint16_t)(crc >> 1);
        }
    }

    return crc;
}

static int write_crc(const char *path, unsigned int digits, uint32_t value)
{
    FILE *stream = fopen(path, "wb");
    int write_failed;

    if (stream == NULL) {
        fprintf(stderr, "error: cannot write '%s': %s\n", path, strerror(errno));
        return 0;
    }

    write_failed = fprintf(stream, "0x%0*" PRIX32 "\n", (int)digits, value) < 0;
    if (fclose(stream) != 0) {
        write_failed = 1;
    }
    if (write_failed) {
        fprintf(stderr, "error: cannot finish '%s'\n", path);
        return 0;
    }

    return 1;
}

static int parse_arguments(int argc, char **argv, Arguments *arguments)
{
    int index;

    memset(arguments, 0, sizeof(*arguments));
    if (argc < 2) {
        return 0;
    }

    arguments->mode = argv[1];
    for (index = 2; index < argc; index += 2) {
        const char *option;
        const char *value;

        if (index + 1 >= argc) {
            return 0;
        }

        option = argv[index];
        value = argv[index + 1];
        if (strcmp(option, "--image") == 0) {
            arguments->image_path = value;
        } else if (strcmp(option, "--reference") == 0) {
            arguments->reference_path = value;
        } else if (strcmp(option, "--range-end") == 0) {
            arguments->range_end_text = value;
        } else if (strcmp(option, "--expected") == 0) {
            arguments->expected_text = value;
        } else if (strcmp(option, "--private-fill-start") == 0) {
            arguments->fill_start_text = value;
        } else if (strcmp(option, "--private-fill-end") == 0) {
            arguments->fill_end_text = value;
        } else if (strcmp(option, "--write") == 0) {
            arguments->write_path = value;
        } else {
            fprintf(stderr, "error: unknown option '%s'\n", option);
            return 0;
        }
    }

    return 1;
}

static int run_official(const Arguments *arguments)
{
    FileData image;
    uint32_t range_end;
    uint32_t fill_start;
    uint32_t fill_end;
    uint32_t expected;
    uint32_t actual;
    int result = 1;

    if (arguments->image_path == NULL || arguments->range_end_text == NULL ||
        arguments->fill_start_text == NULL || arguments->fill_end_text == NULL ||
        arguments->expected_text == NULL || arguments->write_path == NULL ||
        !parse_u32(arguments->range_end_text, &range_end) ||
        !parse_u32(arguments->fill_start_text, &fill_start) ||
        !parse_u32(arguments->fill_end_text, &fill_end) ||
        !parse_u32(arguments->expected_text, &expected)) {
        fprintf(stderr, "error: crc32-official needs valid image, range, fill, expected, and write options\n");
        return 0;
    }

    if (!read_file(arguments->image_path, &image)) {
        return 0;
    }

    if (image.size != NINTENDO_FIRMWARE_BYTES) {
        fprintf(stderr, "error: '%s' must be exactly 0x%X bytes, found 0x%zX\n",
                arguments->image_path, NINTENDO_FIRMWARE_BYTES, image.size);
        result = 0;
    } else if (range_end == 0 || range_end > image.size ||
               fill_start > fill_end || fill_end > range_end) {
        fprintf(stderr, "error: invalid CRC-32 range or private fill range\n");
        result = 0;
    } else {
        actual = crc32_iso_hdlc(image.bytes, range_end, fill_start, fill_end);
        if (actual != expected) {
            fprintf(stderr,
                    "FAIL CRC-32/ISO-HDLC: got 0x%08" PRIX32
                    ", expected 0x%08" PRIX32 " [%s, 0x000000..0x%06" PRIX32 ")\n",
                    actual, expected, arguments->image_path, range_end);
            result = 0;
        } else if (!write_crc(arguments->write_path, 8, actual)) {
            result = 0;
        } else {
            printf("PASS CRC-32/ISO-HDLC: 0x%08" PRIX32
                   " [%s, 0x000000..0x%06" PRIX32
                   "), private 0x%04" PRIX32 "..0x%04" PRIX32 " = FF\n",
                   actual, arguments->image_path, range_end, fill_start, fill_end);
        }
    }

    free_file(&image);
    return result;
}

static int run_flashme(const Arguments *arguments)
{
    FileData image;
    FileData reference;
    uint32_t range_end;
    uint32_t expected_u32;
    uint16_t expected;
    uint16_t image_crc;
    uint16_t reference_crc;
    int result = 1;

    if (arguments->image_path == NULL || arguments->reference_path == NULL ||
        arguments->range_end_text == NULL || arguments->expected_text == NULL ||
        arguments->write_path == NULL ||
        !parse_u32(arguments->range_end_text, &range_end) ||
        !parse_u32(arguments->expected_text, &expected_u32) ||
        expected_u32 > UINT16_MAX) {
        fprintf(stderr, "error: crc16-flashme needs valid image, reference, range, expected, and write options\n");
        return 0;
    }
    expected = (uint16_t)expected_u32;

    if (!read_file(arguments->image_path, &image)) {
        return 0;
    }
    if (!read_file(arguments->reference_path, &reference)) {
        free_file(&image);
        return 0;
    }

    if (image.size != NINTENDO_FIRMWARE_BYTES) {
        fprintf(stderr, "error: rebuilt image '%s' must be exactly 0x%X bytes, found 0x%zX\n",
                arguments->image_path, NINTENDO_FIRMWARE_BYTES, image.size);
        result = 0;
    } else if (range_end == 0 || range_end > image.size || range_end > reference.size) {
        fprintf(stderr, "error: invalid CRC-16 range for '%s' or '%s'\n",
                arguments->image_path, arguments->reference_path);
        result = 0;
    } else {
        reference_crc = crc16_ibm(reference.bytes, range_end);
        image_crc = crc16_ibm(image.bytes, range_end);
        if (reference_crc != expected) {
            fprintf(stderr,
                    "FAIL reference CRC-16/IBM: got 0x%04" PRIX16
                    ", expected 0x%04" PRIX16 " [%s]\n",
                    reference_crc, expected, arguments->reference_path);
            result = 0;
        } else if (image_crc != expected) {
            fprintf(stderr,
                    "FAIL rebuilt CRC-16/IBM: got 0x%04" PRIX16
                    ", expected 0x%04" PRIX16 " [%s]\n",
                    image_crc, expected, arguments->image_path);
            result = 0;
        } else if (!write_crc(arguments->write_path, 4, image_crc)) {
            result = 0;
        } else {
            printf("PASS CRC-16/IBM: 0x%04" PRIX16
                   " [%s, 0x000000..0x%06" PRIX32
                   ") matches %s\n",
                   image_crc, arguments->image_path, range_end, arguments->reference_path);
        }
    }

    free_file(&reference);
    free_file(&image);
    return result;
}

static int run_record(const Arguments *arguments)
{
    FileData image;
    uint32_t range_end;
    uint16_t actual;
    int result = 1;

    if (arguments->image_path == NULL || arguments->range_end_text == NULL ||
        arguments->write_path == NULL ||
        !parse_u32(arguments->range_end_text, &range_end)) {
        fprintf(stderr, "error: crc16-record needs valid image, range, and write options\n");
        return 0;
    }

    if (!read_file(arguments->image_path, &image)) {
        return 0;
    }

    if (image.size != NINTENDO_FIRMWARE_BYTES) {
        fprintf(stderr, "error: rebuilt image '%s' must be exactly 0x%X bytes, found 0x%zX\n",
                arguments->image_path, NINTENDO_FIRMWARE_BYTES, image.size);
        result = 0;
    } else if (range_end == 0 || range_end > image.size) {
        fprintf(stderr, "error: invalid CRC-16 range\n");
        result = 0;
    } else {
        actual = crc16_ibm(image.bytes, range_end);
        if (!write_crc(arguments->write_path, 4, actual)) {
            result = 0;
        } else {
            printf("INFO CRC-16/IBM: 0x%04" PRIX16
                   " [%s, 0x000000..0x%06" PRIX32
                   ") recorded without a historical reference\n",
                   actual, arguments->image_path, range_end);
        }
    }

    free_file(&image);
    return result;
}

int main(int argc, char **argv)
{
    Arguments arguments;

    if (argc == 2 &&
        (strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0)) {
        usage(argv[0]);
        return EXIT_SUCCESS;
    }

    if (!parse_arguments(argc, argv, &arguments)) {
        usage(argc > 0 ? argv[0] : "flashmecrc");
        return EXIT_FAILURE;
    }

    if (strcmp(arguments.mode, "crc32-official") == 0) {
        return run_official(&arguments) ? EXIT_SUCCESS : EXIT_FAILURE;
    }
    if (strcmp(arguments.mode, "crc16-flashme") == 0) {
        return run_flashme(&arguments) ? EXIT_SUCCESS : EXIT_FAILURE;
    }
    if (strcmp(arguments.mode, "crc16-record") == 0) {
        return run_record(&arguments) ? EXIT_SUCCESS : EXIT_FAILURE;
    }

    fprintf(stderr, "error: unknown mode '%s'\n", arguments.mode);
    usage(argv[0]);
    return EXIT_FAILURE;
}
