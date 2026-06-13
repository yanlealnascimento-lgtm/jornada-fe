import { UserModel } from '../users/user.model';

const LEVEL_TABLE: Record<number, number> = {
  1: 0, 2: 100, 3: 250, 4: 450, 5: 700,
  6: 1000, 7: 1400, 8: 1900, 9: 2500, 10: 3200,
};

const LEVEL_NAMES: Record<number, string> = {
  1: 'Semente', 5: 'Discípulo', 10: 'Aprendiz',
  20: 'Servidor', 35: 'Profeta', 50: 'Apóstolo',
  75: 'Ancião', 100: 'Fiel'
};

export class PFService {
  /**
   * Adiciona PF ao usuário e verifica se subiu de nível.
   */
  async addPF(userId: string, amount: number): Promise<{
    newPF: number,
    newLevel: number,
    leveledUp: boolean,
    levelName: string
  }> {
    const user = await UserModel.findById(userId);
    if (!user) throw new Error('User not found');

    const newTotalPF = user.pf_total + amount;
    const currentLevel = user.level;
    const calculatedLevel = this.calculateLevel(newTotalPF);

    const leveledUp = calculatedLevel > currentLevel;

    user.pf_total = newTotalPF;
    if (leveledUp) {
      user.level = calculatedLevel;
    }

    user.pf_to_next_level = this.pfToNextLevel(newTotalPF);
    await user.save();

    return {
      newPF: newTotalPF,
      newLevel: user.level,
      leveledUp,
      levelName: this.getLevelName(user.level)
    };
  }

  calculateLevel(totalPF: number): number {
    let level = 1;
    let nextThreshold = LEVEL_TABLE[level + 1];

    if (totalPF < LEVEL_TABLE[2]) return 1;
    if (totalPF < LEVEL_TABLE[10]) {
       for(let i=1; i<=10; i++){
          if(LEVEL_TABLE[i] > totalPF) return i - 1;
       }
    }

    // Fórmula para Nível > 10 (fallback se tabela não cobrir)
    while (true) {
      let threshold = nextThreshold ? nextThreshold : (level * level * 40 + level * 60);
      if (totalPF >= threshold) {
        level++;
        nextThreshold = ((level + 1) * (level + 1) * 40 + (level + 1) * 60);
      } else {
        break;
      }
    }
    return level;
  }

  pfToNextLevel(currentPF: number): number {
    const currentLevel = this.calculateLevel(currentPF);
    const nextLevelPF = LEVEL_TABLE[currentLevel + 1] || ((currentLevel + 1) * (currentLevel + 1) * 40 + (currentLevel + 1) * 60);
    return nextLevelPF - currentPF;
  }

  getLevelName(level: number): string {
    const milestones = Object.keys(LEVEL_NAMES).map(Number).sort((a,b) => b - a);
    for (const m of milestones) {
      if (level >= m) return LEVEL_NAMES[m];
    }
    return LEVEL_NAMES[1] || 'Semente';
  }
}
