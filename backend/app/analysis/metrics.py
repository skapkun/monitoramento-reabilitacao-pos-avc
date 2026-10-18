import numpy as np

from app.analysis.models import Landmark


def joint_angle_degrees(a: Landmark, vertex: Landmark, c: Landmark) -> float:
    first = np.array([a.x - vertex.x, a.y - vertex.y], dtype=float)
    second = np.array([c.x - vertex.x, c.y - vertex.y], dtype=float)
    denominator = float(np.linalg.norm(first) * np.linalg.norm(second))
    if denominator <= 1e-9:
        raise ValueError("Não é possível calcular o ângulo com pontos coincidentes.")
    cosine = float(np.clip(np.dot(first, second) / denominator, -1.0, 1.0))
    return float(np.degrees(np.arccos(cosine)))


def euclidean_distance(a: Landmark, b: Landmark) -> float:
    return float(np.linalg.norm(np.array([a.x - b.x, a.y - b.y], dtype=float)))
