"""
Plot test results for different LLMs' ability to write the required quality of Cypher to
answer the user's questions.
"""

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.colors import ListedColormap

RED = "#8B0000"
GREEN = "#006400"

# Full schema results (no pruning)
json_results_full = {
    "openai/gpt-4.1": "............F.................",
    "google/gemini-2.5-flash": "......FF....F...F.....F.F.F...",
    "google/gemini-2.0-flash": "......F.....F...F.............",
    "mistralai/devstral-medium": "....F.F..F.FF........F..F..F..",
    "openai/gpt-4.1-nano": "....F.FF.FF.FF.FFF...FF.F.FFF.",
}

xml_results_full = {
    "openai/gpt-4.1": "..F.........F........F........",
    "google/gemini-2.5-flash": "...FF.FF.F....F.......F...F.F.",
    "google/gemini-2.0-flash": "......F.....F.F...........F...",
    "mistralai/devstral-medium": "....F.F..F.F.........FF.F.FF..",
    "openai/gpt-4.1-nano": "....F.F.FFFFFFF.FF....F.F...F.",
}

yaml_results_full = {
    "openai/gpt-4.1": "......F.....F...........F..F..",
    "google/gemini-2.5-flash": "....F.FF.F..F.F.......F...FF..",
    "google/gemini-2.0-flash": "......F.....F.................",
    "mistralai/devstral-medium": "....F.F..F.FF........F..F..F..",
    "openai/gpt-4.1-nano": "..F.F.FF.FFFFFF.F...F.F.F.F.F.",
}

# Pruned schema results
json_results_pruned = {
    "openai/gpt-4.1": "..............................",
    "google/gemini-2.5-flash": "..........F...F...............",
    "google/gemini-2.0-flash": "..........F...................",
    "mistralai/devstral-medium": "......................F.......",
    "openai/gpt-4.1-nano": "......FF....F.F.FF...FF.F...F.",
}

xml_results_pruned = {
    "openai/gpt-4.1": "..............................",
    "google/gemini-2.5-flash": "......F.....F...F.........F...",
    "google/gemini-2.0-flash": "............F.................",
    "mistralai/devstral-medium": "...........................F..",
    "openai/gpt-4.1-nano": "....F.FFFFFFF.F.FF...FF.F.F.F.",
}

yaml_results_pruned = {
    "openai/gpt-4.1": "..F...........................",
    "google/gemini-2.5-flash": "............F...F.........F...",
    "google/gemini-2.0-flash": "..............................",
    "mistralai/devstral-medium": "......FF.F............F....F..",
    "openai/gpt-4.1-nano": "..F.F.FF....F.F.FF...FF....F..",
}


def parse_results(results_dict):
    """Convert string results to binary matrix"""
    models = list(results_dict.keys())
    num_tests = len(list(results_dict.values())[0])

    matrix = np.zeros((len(models), num_tests))

    for i, (_, result_str) in enumerate(results_dict.items()):
        for j, char in enumerate(result_str):
            matrix[i, j] = 1 if char == "." else 0  # 1 for pass (.), 0 for fail (F)

    return matrix, models


def main():
    # --- Plot 1: Full schema results ---
    full_results = [
        (json_results_full, "JSON (Full Schema)"),
        (xml_results_full, "XML (Full Schema)"),
        (yaml_results_full, "YAML (Full Schema)"),
    ]
    fig1, axes1 = plt.subplots(1, 3, figsize=(18, 3))
    for idx, (results_dict, title) in enumerate(full_results):
        matrix, models = parse_results(results_dict)
        ax = axes1[idx]
        colors = [RED, GREEN]  # Red for fail, green for pass
        cmap = ListedColormap(colors)
        _ = ax.imshow(matrix, cmap=cmap, aspect="auto", vmin=0, vmax=1)
        ax.set_xticks(range(matrix.shape[1]))
        ax.set_xticklabels([f"Q{i+1}" for i in range(matrix.shape[1])], fontsize=6)
        ax.set_yticks(range(len(models)))
        ax.set_yticklabels(models, fontsize=8)
        # ax.set_title(title, fontsize=12, fontweight="bold", pad=10)
        ax.set_xticks(np.arange(-0.5, matrix.shape[1], 1), minor=True)
        ax.set_yticks(np.arange(-0.5, len(models), 1), minor=True)
        ax.grid(True, which="minor", color="white", linewidth=0.1)
        plt.setp(ax.get_xticklabels(), rotation=45, ha="right")

    fig1.suptitle("Full Schema Results (No Pruning)", fontsize=16, fontweight="bold", y=1.05)
    plt.tight_layout()
    plt.savefig("full_schema_results.png", dpi=300, bbox_inches="tight")

    # --- Plot 2: Pruned schema results ---
    pruned_results = [
        (json_results_pruned, "JSON (Pruned Schema)"),
        (xml_results_pruned, "XML (Pruned Schema)"),
        (yaml_results_pruned, "YAML (Pruned Schema)"),
    ]
    fig2, axes2 = plt.subplots(1, 3, figsize=(18, 3))
    for idx, (results_dict, title) in enumerate(pruned_results):
        matrix, models = parse_results(results_dict)
        ax = axes2[idx]
        colors = [RED, GREEN]  # Red for fail, green for pass
        cmap = ListedColormap(colors)
        _ = ax.imshow(matrix, cmap=cmap, aspect="auto", vmin=0, vmax=1)
        ax.set_xticks(range(matrix.shape[1]))
        ax.set_xticklabels([f"Q{i+1}" for i in range(matrix.shape[1])], fontsize=6)
        ax.set_yticks(range(len(models)))
        ax.set_yticklabels(models, fontsize=8)
        # ax.set_title(title, fontsize=12, fontweight="bold", pad=10)
        ax.set_xticks(np.arange(-0.5, matrix.shape[1], 1), minor=True)
        ax.set_yticks(np.arange(-0.5, len(models), 1), minor=True)
        ax.grid(True, which="minor", color="white", linewidth=0.1)
        plt.setp(ax.get_xticklabels(), rotation=45, ha="right")

    fig2.suptitle("Pruned Schema Results", fontsize=16, fontweight="bold", y=1.05)
    plt.tight_layout()
    plt.savefig("pruned_schema_results.png", dpi=300, bbox_inches="tight")


if __name__ == "__main__":
    main()
