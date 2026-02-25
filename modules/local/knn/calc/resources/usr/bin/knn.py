#!/usr/bin/env -S uv run --script --no-cache
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "matplotlib",
#     "numpy",
#     "pandas",
#     "typer",
# ]
# ///
"""Run K-nearest-neighbor ancestry prediction from PCA coordinates."""

from __future__ import annotations

from pathlib import Path
from typing import Annotated

import matplotlib
import numpy as np
import pandas as pd
import typer

matplotlib.use("Agg")
import matplotlib.pyplot as plt

app = typer.Typer(add_completion=False, help="KNN ancestry prediction from PCA coordinates.")


def read_input_tables(
    eig_path: Path,
    labels_path: Path,
    sep: str,
    id_col: str,
    label_col: str,
) -> pd.DataFrame:
    """Read PCA and label tables, validate required columns, and merge by ID."""
    eig = pd.read_csv(eig_path, sep=sep)
    labels = pd.read_csv(labels_path, sep=sep)

    required_eig_cols = {id_col}
    required_label_cols = {id_col, label_col}
    missing_eig = required_eig_cols - set(eig.columns)
    missing_lab = required_label_cols - set(labels.columns)

    if missing_eig:
        raise typer.BadParameter(
            f"Missing required column(s) in eig file: {', '.join(sorted(missing_eig))}"
        )
    if missing_lab:
        raise typer.BadParameter(
            f"Missing required column(s) in labels file: {', '.join(sorted(missing_lab))}"
        )

    return eig.merge(labels[[id_col, label_col]], on=id_col, how="left")


def get_pc_columns(df: pd.DataFrame) -> list[str]:
    """Return PCA feature columns named like PC1, PC2, etc."""
    pc_cols = [column for column in df.columns if column.upper().startswith("PC")]
    if not pc_cols:
        raise typer.BadParameter(
            "No PC columns found. Expected columns like PC1, PC2, ..."
        )
    return pc_cols


def sort_pc_columns(pc_cols: list[str]) -> list[str]:
    """Sort PC columns by their numeric suffix when present (PC1, PC2, PC10, ...)."""
    def _pc_sort_key(column: str) -> tuple[int, str]:
        suffix = column[2:]
        return (int(suffix), column) if suffix.isdigit() else (10**9, column)

    return sorted(pc_cols, key=_pc_sort_key)


def split_train_predict(
    merged_df: pd.DataFrame,
    label_col: str,
) -> tuple[pd.DataFrame, pd.DataFrame]:
    """Split merged data into labeled training rows and unlabeled prediction rows."""
    train = merged_df[merged_df[label_col].notna()].copy()
    predict = merged_df[merged_df[label_col].isna()].copy()

    if train.empty:
        raise typer.BadParameter(
            "No labeled samples found after merge. Check if IDs match between files."
        )
    if predict.empty:
        raise typer.BadParameter(
            "No unlabeled samples found. Nothing to predict."
        )

    return train, predict


def standardize_train_query(
    train_features: np.ndarray,
    query_features: np.ndarray,
) -> tuple[np.ndarray, np.ndarray]:
    """Standardize features using training-set mean and standard deviation."""
    mean = train_features.mean(axis=0)
    std = train_features.std(axis=0)
    std[std == 0] = 1.0
    return (train_features - mean) / std, (query_features - mean) / std


def predict_knn(
    train_features: np.ndarray,
    train_labels: np.ndarray,
    query_features: np.ndarray,
    k: int,
) -> tuple[np.ndarray, np.ndarray]:
    """Predict class labels and confidence scores using a simple KNN vote."""
    if k < 1:
        raise typer.BadParameter("k must be >= 1.")

    effective_k = min(k, len(train_labels))
    predicted_labels: list[str] = []
    confidences: list[float] = []

    for query_row in query_features:
        distances = np.sum((train_features - query_row) ** 2, axis=1)
        neighbor_idx = np.argpartition(distances, effective_k - 1)[:effective_k]
        neighbor_labels = train_labels[neighbor_idx]

        labels, counts = np.unique(neighbor_labels, return_counts=True)
        winner_index = int(np.argmax(counts))
        predicted_labels.append(str(labels[winner_index]))
        confidences.append(float(counts[winner_index] / effective_k))

    return np.array(predicted_labels), np.array(confidences)


def write_predictions(
    sample_ids: np.ndarray,
    predicted_labels: np.ndarray,
    confidences: np.ndarray,
    output_path: Path,
) -> None:
    """Write KNN predictions to a tab-separated output file."""
    out_df = pd.DataFrame(
        {
            "#IID": sample_ids,
            "pred_group": predicted_labels,
            "knn_conf": confidences,
        }
    )
    out_df.to_csv(output_path, sep="\t", index=False)


def write_pca_plot(
    train_df: pd.DataFrame,
    predict_df: pd.DataFrame,
    predicted_labels: np.ndarray,
    pc_x: str,
    pc_y: str,
    label_col: str,
    output_path: Path,
) -> None:
    """Generate a PCA scatter plot colored by cluster/group labels."""
    plot_train = train_df[[pc_x, pc_y, label_col]].copy()
    plot_train["cluster"] = plot_train[label_col].astype(str)
    plot_train["source"] = "reference"

    plot_predict = predict_df[[pc_x, pc_y]].copy()
    plot_predict["cluster"] = predicted_labels
    plot_predict["source"] = "predicted"

    plot_df = pd.concat(
        [
            plot_train[[pc_x, pc_y, "cluster", "source"]],
            plot_predict[[pc_x, pc_y, "cluster", "source"]],
        ],
        ignore_index=True,
    )

    clusters = sorted(plot_df["cluster"].unique())
    cmap = plt.cm.get_cmap("tab20", max(len(clusters), 1))
    color_map = {cluster: cmap(i) for i, cluster in enumerate(clusters)}

    fig, ax = plt.subplots(figsize=(8, 6))

    for cluster in clusters:
        cluster_train = plot_df[(plot_df["cluster"] == cluster) & (plot_df["source"] == "reference")]
        cluster_pred = plot_df[(plot_df["cluster"] == cluster) & (plot_df["source"] == "predicted")]
        color = color_map[cluster]

        if not cluster_train.empty:
            ax.scatter(
                cluster_train[pc_x],
                cluster_train[pc_y],
                s=28,
                alpha=0.75,
                color=color,
                edgecolors="none",
                label=str(cluster),
            )

        if not cluster_pred.empty:
            ax.scatter(
                cluster_pred[pc_x],
                cluster_pred[pc_y],
                s=80,
                alpha=1.0,
                marker="X",
                color=color,
                edgecolors="black",
                linewidths=0.6,
            )

    ax.set_xlabel(pc_x)
    ax.set_ylabel(pc_y)
    ax.set_title("PCA Clusters with KNN Predictions")

    handles, labels = ax.get_legend_handles_labels()
    if handles:
        by_label = dict(zip(labels, handles))
        ax.legend(by_label.values(), by_label.keys(), title="Cluster", bbox_to_anchor=(1.02, 1), loc="upper left")

    fig.tight_layout()
    fig.savefig(output_path, dpi=200)
    plt.close(fig)


@app.command()
def main(
    eig: Annotated[
        Path,
        typer.Option(
            "--eig",
            "-e",
            exists=True,
            dir_okay=False,
            readable=True,
            help="PCA table with ID and PC columns.",
        ),
    ],
    labels: Annotated[
        Path,
        typer.Option(
            "--labels",
            "-l",
            exists=True,
            dir_okay=False,
            readable=True,
            help="Label table with ID and group label columns.",
        ),
    ],
    output: Annotated[
        Path,
        typer.Option("--output", "-o", help="Output TSV path."),
    ] = Path("knn_pred.tsv"),
    k: Annotated[int, typer.Option("--k", "-k", min=1, help="Number of neighbors.")] = 5,
    id_col: Annotated[str, typer.Option("--id-col", help="Sample ID column name.")] = "#IID",
    label_col: Annotated[str, typer.Option("--label-col", help="Label column name.")] = "SuperPop",
    sep: Annotated[str, typer.Option("--sep", help="Input delimiter used by both files.")] = "\t",
    normalize: Annotated[
        bool, typer.Option("--normalize/--no-normalize", help="Standardize PC columns.")
    ] = True,
    plot: Annotated[
        bool, typer.Option("--plot/--no-plot", help="Generate PCA scatter plot.")
    ] = True,
    plot_output: Annotated[
        Path, typer.Option("--plot-output", help="Output PNG path for PCA scatter plot.")
    ] = Path("knn_pca.png"),
) -> None:
    """Run the KNN workflow from CLI arguments and write prediction output."""
    merged_df = read_input_tables(
        eig_path=eig,
        labels_path=labels,
        sep=sep,
        id_col=id_col,
        label_col=label_col,
    )
    pc_cols = sort_pc_columns(get_pc_columns(merged_df))
    if plot and len(pc_cols) < 2:
        raise typer.BadParameter(
            "At least two PC columns are required to generate a PCA plot."
        )
    train_df, predict_df = split_train_predict(merged_df, label_col=label_col)

    train_features = train_df[pc_cols].to_numpy(dtype=float)
    query_features = predict_df[pc_cols].to_numpy(dtype=float)
    train_labels = train_df[label_col].to_numpy(dtype=str)

    if normalize:
        train_features, query_features = standardize_train_query(
            train_features=train_features,
            query_features=query_features,
        )

    predicted_labels, confidences = predict_knn(
        train_features=train_features,
        train_labels=train_labels,
        query_features=query_features,
        k=k,
    )

    write_predictions(
        sample_ids=predict_df[id_col].to_numpy(),
        predicted_labels=predicted_labels,
        confidences=confidences,
        output_path=output,
    )
    if plot:
        write_pca_plot(
            train_df=train_df,
            predict_df=predict_df,
            predicted_labels=predicted_labels,
            pc_x=pc_cols[0],
            pc_y=pc_cols[1],
            label_col=label_col,
            output_path=plot_output,
        )
        typer.echo(f"Wrote {plot_output}")
    typer.echo(f"Wrote {output}")


if __name__ == "__main__":
    app()
