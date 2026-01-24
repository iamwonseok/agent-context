# Make-04-01: Use ${VAR} format for variables - FAIL (uses parentheses)
# Tool: checkmake

CC       := gcc
CFLAGS   := -Wall -Werror
LDFLAGS  := -lm
SRC_DIR  := src
OBJ_DIR  := obj
TARGET   := main

SOURCES  := $(wildcard $(SRC_DIR)/*.c)
OBJECTS  := $(SOURCES:$(SRC_DIR)/%.c=$(OBJ_DIR)/%.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CC) $(LDFLAGS) -o $@ $^

$(OBJ_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(OBJ_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	$(RM) -r $(OBJ_DIR) $(TARGET)
