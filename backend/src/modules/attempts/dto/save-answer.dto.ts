import { IsIn, IsString } from 'class-validator';

export class SaveAnswerDto {
  @IsString()
  questionId!: string;

  @IsIn(['A', 'B', 'C', 'D'])
  selectedOption!: 'A' | 'B' | 'C' | 'D';
}
